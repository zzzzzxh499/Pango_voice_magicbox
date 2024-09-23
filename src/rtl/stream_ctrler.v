module stream_ctrler(
    input               rst_n              ,
    //iis in
    input               sclk               , //26M from iis
    input               l_lvd              , //iis edge lval
    input [15:0]        rx_data            , //iis data
    output              l_lvd_out          , //iis data valid
    output [15:0]       tx_data            , //iis data
    //fft interface
    input               i_aclk             ,
    input               i_axi4s_data_tready,
    output reg          o_axi4s_data_tvalid,
    output reg [31:0]   o_axi4s_data_tdata ,
    output reg          o_axi4s_data_tlast ,
    output reg          o_axi4s_cfg_tvalid ,
    output              o_axi4s_cfg_tdata  ,
    input               i_axi4s_data_tvalid,
    input [63:0]        i_axi4s_data_tdata ,
    input               i_axi4s_data_tlast ,
    input               i_stat             ,

    //algorithm interface
    output [4:0]        current_state      ,//当前状态

    input [31:0]        freq_data          ,
    input               freq_valid         ,
    input               freq_last          );

parameter FRAME_LENTH = 1024;
localparam FRAME_WIDTH = $clog2(FRAME_LENTH);

localparam S0 = 5'b00001;// 等待ip准备好
localparam S1 = 5'b00010;// 读fifo 做fft
localparam S2 = 5'b00100;// 存储fft结果到ram
localparam S3 = 5'b01000;// 实现算法 做ifft
localparam S4 = 5'b10000;// 存储ifft结果到fifo

reg wr_en;// fifo write enable
wire almost_empty,almost_full;
reg fft_mode;
reg [4:0] state;
reg [FRAME_WIDTH:0] rd_addr;
reg [5:0] tready_d;
wire pos_tready;

wire [15:0] rx_data_fifo;
wire rd_en1;
reg l_valid_tmp , l_valid;
wire wr_en2;

assign current_state = state;

///////////////////////////// sclk clock region ////////////////////

always @(posedge sclk)
if(~rst_n) wr_en <= 1'b0;
else wr_en <= l_lvd;


///////////////////////////// aclk clock region ////////////////////

// fft ip config

always @(posedge i_aclk)
if(~rst_n) tready_d <= 6'd0;
else tready_d <= {tready_d[4:0],i_axi4s_data_tready};


assign pos_tready = (tready_d[4] & ~tready_d[5]);

always @(posedge i_aclk)
if(~rst_n) o_axi4s_cfg_tvalid <= 1'b0;
else if(o_axi4s_cfg_tvalid) o_axi4s_cfg_tvalid <= 1'b0;
else if (i_stat) o_axi4s_cfg_tvalid <= 1'b1;
else o_axi4s_cfg_tvalid <= 1'b0;

assign o_axi4s_cfg_tdata = fft_mode;

// fft data
always @(posedge i_aclk)
if(~rst_n) state <= S0;
else case(state)
S0: begin
  if(~almost_empty && tready_d[4]) state <= S1;
  else state <= S0;
end
S1: begin // 读fifo 做fft
  if(rd_addr == (FRAME_LENTH-1)) state <= S2;
  else state <= S1;
end
S2: begin // 存储fft结果到ram
  if(pos_tready) state <= S3;
  else state <= S2;
end
S3: begin // 实现算法 做ifft
  if(freq_last) state <= S4;
  else state <= S3;
end
S4: begin // 存储ifft结果到fifo
  if(pos_tready) state <= S0;
  else state <= S4;
end
default: state <= S0;
endcase

always @(posedge i_aclk)
if(~rst_n) fft_mode <= 1'b1;
else case(state)
S0: fft_mode <= 1'b1;
S1: fft_mode <= 1'b1;
S2: fft_mode <= 1'b1;
S3: fft_mode <= 1'b0;
default: fft_mode <= 1'b1;
endcase

always @(posedge i_aclk)
if(~rst_n) rd_addr <= 'd0;
else if(state == S1) 
  rd_addr <= rd_addr + 1'b1;
else rd_addr <= 'd0; 

always @(posedge i_aclk)
if(~rst_n) o_axi4s_data_tdata <= 'd0;
else case(state)
S1: o_axi4s_data_tdata <= {16'd0,rx_data_fifo};
S3: o_axi4s_data_tdata <= freq_data;
default: o_axi4s_data_tdata <= 'd0;
endcase

always @(posedge i_aclk)
if(~rst_n) o_axi4s_data_tvalid <= 1'b0;
else case(state)
S1: o_axi4s_data_tvalid <= 1'b1;
S3: o_axi4s_data_tvalid <= freq_valid;
default: o_axi4s_data_tvalid <= 1'b0;
endcase

always @(posedge i_aclk)
if(~rst_n) o_axi4s_data_tlast <= 1'b0;
else case(state)
S1: o_axi4s_data_tlast <= rd_addr == (FRAME_LENTH-1);
S3: o_axi4s_data_tlast <= freq_last;
default: o_axi4s_data_tlast <= 1'b0;
endcase

always @(posedge i_aclk)
if(~rst_n) l_valid_tmp <= 1'b0;
else if(wr_en2) l_valid_tmp <= 1'b1;
else l_valid_tmp <= l_valid_tmp;

always @(posedge sclk)
if(~rst_n) l_valid <= 1'b0;
else if(l_lvd) l_valid <= l_valid_tmp;
else l_valid <= l_valid;

assign rd_en1 = state == S1;
assign wr_en2 = state == S4 && i_axi4s_data_tvalid;
assign l_lvd_out = wr_en && l_valid;

assign freq_ready = state == S3; //可以进行频域算法

// fifo

FIFO_1 FIFO_RX(
  .wr_clk                   (sclk               ),    // input
  .wr_rst                   (~rst_n             ),    // input
  .wr_en                    (wr_en              ),    // input
  .wr_data                  (rx_data            ),    // input [15:0]
  .almost_full              (almost_full        ),    // output
  .rd_clk                   (i_aclk             ),    // input
  .rd_rst                   (~rst_n             ),    // input
  .rd_en                    (rd_en1             ),    // input
  .rd_data                  (rx_data_fifo       ),    // output [15:0]
  .almost_empty             (almost_empty       )     // output
);

FIFO_1 FIFO_TX(
  .wr_clk                   (i_aclk             ),    // input
  .wr_rst                   (~rst_n             ),    // input
  .wr_en                    (wr_en2             ),    // input
  .wr_data                  ({i_axi4s_data_tdata[14:0],1'b0}),    // input [15:0]
  .almost_full              (        ),    // output
  .rd_clk                   (sclk             ),    // input
  .rd_rst                   (~rst_n             ),    // input
  .rd_en                    (l_valid && l_lvd    ),    // input
  .rd_data                  (tx_data       ),    // output [15:0]
  .almost_empty             (       )     // output
);


endmodule