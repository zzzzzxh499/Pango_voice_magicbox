module hann(
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
    output [31:0]   o_axi4s_data_tdata ,
    output reg          o_axi4s_data_tlast ,
    output reg          o_axi4s_cfg_tvalid ,
    output              o_axi4s_cfg_tdata  ,
    input               i_axi4s_data_tvalid,
    input [63:0]        i_axi4s_data_tdata ,
    input               i_axi4s_data_tlast ,
    input               i_stat             ,

    //algorithm interface
    output [4:0]        current_state      ,//当前状态
    output              fft_storing        ,
    output              fft_stored         ,

    input [31:0]        freq_data          ,
    input               freq_valid         ,
    input               freq_last          );

parameter FRAME_LENTH = 1024;
localparam FRAME_WIDTH = $clog2(FRAME_LENTH);

localparam IDLE     = 5'b00000;// wait fft ip ready
localparam FFT_HANN = 5'b00001;// add hann window
localparam FFT_FIFO = 5'b00010;// fft processing
localparam FFT_ST   = 5'b00100;// Spectrum storage
localparam IFFT     = 5'b01000;// algorithm + ifft processing
localparam IFFT_ST  = 5'b10000;// add hann window  ifft -> txfifo

reg rxff_wren,orgff_wren;// fifo write enable
wire almost_empty,almost_full;
reg fft_mode;
reg [4:0] state;
reg [FRAME_WIDTH:0] rd_addr;
reg [5:0] tready_d;
wire pos_tready;

wire [15:0] rx_data_fifo;
wire [15:0] rd_data_hann;
reg rxff_rden;
reg orgff_rden;
reg l_valid_tmp , l_valid;
reg txff_wren;
reg signed [15:0] txff_data;

reg [9:0] lut_addr;
wire [15:0] hann_par;
reg [15:0] time_data;
wire signed [31:0] hann_data;

wire time_data_valid;
reg [3:0] time_valid_d;
wire time_data_last;
reg [3:0] org_last_d;
wire signed [15:0] mul_result; //window result

wire ifft_result_valid;
wire fftff_wren,fftff_rden;
wire signed [15:0] fft_data_hann;
reg [15:0] ifft_result_data;

reg iresult_valid_d0,iresult_valid_d1,iresult_valid_d2;

assign current_state = state;
assign fft_stored = state == IFFT;
assign fft_storing = state == FFT_ST;
assign time_data_valid = state==FFT_FIFO||state==FFT_HANN||ifft_result_valid;
assign time_data_last = state==FFT_FIFO&&rd_addr == FRAME_LENTH/2-1;
assign mul_result = hann_data>>>15;
///////////////////////////// sclk clock region ////////////////////

always @(posedge sclk)
if(~rst_n) rxff_wren <= 1'b0;
else rxff_wren <= l_lvd;


// send start

always @(posedge i_aclk)
if(~rst_n) l_valid_tmp <= 1'b0;
else if(txff_wren) l_valid_tmp <= 1'b1;
else l_valid_tmp <= l_valid_tmp;

always @(posedge sclk)
if(~rst_n) l_valid <= 1'b0;
else if(l_lvd) l_valid <= l_valid_tmp;
else l_valid <= l_valid;

///////////////////////////// aclk clock region ////////////////////

// state machine

always @(posedge i_aclk)
if(~rst_n) begin
  state <= IDLE;
  rxff_rden <= 1'b0;
  orgff_rden <= 1'b0;
  rd_addr <= 10'd0;
  o_axi4s_cfg_tvalid <= 1'b0;
end else case(state)
IDLE: begin
  if(~almost_empty && tready_d[4]) begin
    state <= FFT_HANN; //FIFO water level == 512 && FFT ip ready
    orgff_rden <= 1'b1; //pread
  end else begin
    o_axi4s_cfg_tvalid <= 1'b1;
    state <= IDLE;
  end
end
FFT_HANN: begin
  o_axi4s_cfg_tvalid <= 1'b0;
  if(rd_addr == FRAME_LENTH/2-1) begin
    rxff_rden <= 1'b1;
    orgff_rden <= 1'b0;
    rd_addr <= 10'd0;
    state <= FFT_FIFO;
  end else begin
    rxff_rden <= 1'b0;
    orgff_rden <= 1'b1;
    rd_addr <= rd_addr + 1'b1;
    state <= FFT_HANN;
  end
end
FFT_FIFO: begin
  if(rd_addr == FRAME_LENTH/2-1) begin
    rxff_rden <= 1'b0;
    orgff_rden <= 1'b0;
    rd_addr <= 10'd0;
    state <= FFT_ST;
  end else begin
    rxff_rden <= 1'b1;
    orgff_rden <= 1'b0;
    rd_addr <= rd_addr + 1'b1;
    state <= FFT_FIFO;
  end
end
FFT_ST: begin
  if(pos_tready) state <= IFFT;
  else begin
    state <= FFT_ST;
    o_axi4s_cfg_tvalid <= 1'b1;
  end
end
IFFT: begin
  o_axi4s_cfg_tvalid <= 1'b0;
  if(freq_last) state <= IFFT_ST;
  else state <= IFFT;
end
IFFT_ST: begin
  if(pos_tready) state <= IDLE;
  else state <= IFFT_ST;
  if(iresult_valid_d2) 
    if(rd_addr == FRAME_LENTH-1) rd_addr <= 10'd0;
    else rd_addr <= rd_addr + 1'b1;
end
default: state <= IDLE;
endcase


// fft ip config

always @(posedge i_aclk)
if(~rst_n) tready_d <= 6'd0;
else tready_d <= {tready_d[4:0],i_axi4s_data_tready};


assign pos_tready = (tready_d[4] & ~tready_d[5]);

assign o_axi4s_cfg_tdata = fft_mode;

always @(posedge i_aclk)
if(~rst_n) fft_mode <= 1'b1;
else case(state)
IDLE: fft_mode <= 1'b1;
FFT_ST: fft_mode <= 1'b0;
default: fft_mode <= fft_mode;
endcase


// fft ip output data
reg [31:0] freq_data_d;
always @(posedge i_aclk)
if(~rst_n) freq_data_d <= 32'd0;
else freq_data_d <= freq_data;

assign o_axi4s_data_tdata = state==IFFT ? {16'd0,freq_data_d} : {16'd0,mul_result};


always @(posedge i_aclk)
case(state)
FFT_HANN,FFT_FIFO,FFT_ST: o_axi4s_data_tvalid <= time_valid_d[2];
IFFT: o_axi4s_data_tvalid <= freq_valid;
default: o_axi4s_data_tvalid <= 1'b0;
endcase

always @(posedge i_aclk)
if(~rst_n) o_axi4s_data_tlast <= 1'b0;
else case(state)
FFT_ST: o_axi4s_data_tlast <= org_last_d[2];
IFFT: o_axi4s_data_tlast <= freq_last;
default: o_axi4s_data_tlast <= 1'b0;
endcase

always @(posedge i_aclk) // time domain data valid delay 3
if(~rst_n) time_valid_d <= 4'd0;
else time_valid_d <= {time_valid_d[2:0],time_data_valid};

always @(posedge i_aclk)
if(~rst_n) org_last_d <= 4'd0;
else org_last_d <= {org_last_d[2:0],time_data_last};

// sync fifo1 ctrl

always @(posedge i_aclk) 
if(~rst_n) orgff_wren <= 1'b0;
else orgff_wren <= rxff_rden;

assign ifft_result_valid = state == IFFT_ST && i_axi4s_data_tvalid;
assign l_lvd_out = rxff_wren && l_valid;

assign freq_ready = state == IFFT; //algorithm enable

always @(posedge i_aclk)
if(~rst_n) lut_addr <= 10'd0;
else if( (rxff_rden || orgff_rden) || ifft_result_valid) lut_addr <= lut_addr + 1'b1;
else lut_addr <= 10'd0;




// hann window operation

always @(posedge i_aclk)
if(~rst_n) ifft_result_data <= 16'd0;
else ifft_result_data <= i_axi4s_data_tdata[15:0];

always @(*) //time domain data x hann window
case(state)
FFT_HANN: time_data <= rd_data_hann;
FFT_FIFO,FFT_ST: time_data <= rx_data_fifo;
IFFT_ST: time_data <= ifft_result_data;
default : time_data <= 16'd0;
endcase

//multipluxer

MUL16x16 MUL16x16 (
  .a(time_data),        // input [15:0]
  .b(hann_par),        // input [15:0]
  .clk(i_aclk),    // input
  .rst(~rst_n),    // input
  .ce(time_valid_d[0]),      // input
  .p(hann_data)         // output [31:0]
);

// ifft result delay


always @(posedge i_aclk) 
if(~rst_n) begin
  iresult_valid_d0 <= 1'b0;
  iresult_valid_d1 <= 1'b0;
  iresult_valid_d2 <= 1'b0;
end else begin
  iresult_valid_d0 <= ifft_result_valid;
  iresult_valid_d1 <= iresult_valid_d0;
  iresult_valid_d2 <= iresult_valid_d1;
end

assign fftff_rden = iresult_valid_d2 && ~rd_addr[9];
assign fftff_wren = iresult_valid_d2 && rd_addr[9];

always @(posedge i_aclk)
if(~rst_n) begin
  txff_wren <= 1'b0;
  txff_data <= 16'd0;
end else begin
  txff_wren <= fftff_rden;
  txff_data <= mul_result + fft_data_hann;
end

// fifo

FIFO_1 FIFO_RX(
  .wr_clk                   (sclk               ),    // input
  .wr_rst                   (~rst_n             ),    // input
  .wr_en                    (rxff_wren          ),    // input
  .wr_data                  (rx_data            ),    // input [15:0]
  .almost_full              (almost_full        ),    // output
  .rd_clk                   (i_aclk             ),    // input
  .rd_rst                   (~rst_n             ),    // input
  .rd_en                    (rxff_rden          ),    // input
  .rd_data                  (rx_data_fifo       ),    // output [15:0]
  .almost_empty             (almost_empty       )     // output
);

sync_fifo HANN_org_fifo (
  .clk                      (i_aclk             ),    // input
  .rst                      (~rst_n             ),    // input
  .wr_en                    (orgff_wren         ),    // input
  .wr_data                  (rx_data_fifo       ),    // input [15:0]
  .rd_en                    (orgff_rden         ),    // input
  .rd_data                  (rd_data_hann       )     // output [15:0]
);


HANN_LUT HANN_LUT (
  .wr_data                  (16'd0              ),    // input [15:0]
  .addr                     (lut_addr           ),    // input [9:0]
  .wr_en                    (1'b0               ),    // input
  .clk                      (i_aclk             ),    // input
  .rst                      (~rst_n             ),    // input
  .rd_data                  (hann_par           )     // output [15:0]
);

sync_fifo HANN_fft_fifo (
  .clk                      (i_aclk             ),    // input
  .rst                      (~rst_n             ),    // input
  .wr_en                    (fftff_wren         ),    // input
  .wr_data                  (mul_result         ),    // input [15:0]
  .rd_en                    (fftff_rden         ),    // input
  .rd_data                  (fft_data_hann      )     // output [15:0]
);


FIFO_1 FIFO_TX(
  .wr_clk                   (i_aclk             ),    // input
  .wr_rst                   (~rst_n             ),    // input
  .wr_en                    (txff_wren          ),    // input
  .wr_data                  (txff_data          ),    // input [15:0]
  .almost_full              (                   ),    // output
  .rd_clk                   (sclk               ),    // input
  .rd_rst                   (~rst_n             ),    // input
  .rd_en                    (l_valid && l_lvd   ),    // input
  .rd_data                  (tx_data            ),    // output [15:0]
  .almost_empty             (                   )     // output
);


endmodule