module DCT(
    input clk,
    input rst_n,
    input signed [15:0] logFBE,
    input valid,
    output reg signed [15:0] mfcc_tmp,
    output mfcc_tmp_valid,
    output reg [4:0] index
);


reg [15:0] DCT_rom [26*13-1:0];

initial 
  $readmemh("D:/projects/pango/Pango_magicbox/sim/mcode/DCT_f.txt", DCT_rom, 0, 26*13);

wire signed [15:0] logFBE_d;
reg  signed [15:0] logFBE_l;
wire empty;
reg rd_en;
wire clear;
reg [2:0] state;
reg [8:0] dct_index;
reg signed [15:0] dct_data;
reg signed [26:0] hfcc_tmp [12:0];
reg [3:0] cnt1 ;
reg [4:0] cnt2 ;
wire mul_ce;
reg [3:0] mul_ce_d;
reg [3:0] cnt_d0,cnt_d1,cnt_d2,cnt_d3;
wire signed [31:0] fbe_dct;
wire signed [21:0] fbe_dct_t = fbe_dct >>> 10;
wire cul_done;
reg [4:0] cul_done_d;



localparam IDLE     = 3'b001;
localparam HOLD     = 3'b010;
localparam FIFO_RD  = 3'b100;


always @(posedge clk) dct_data <= DCT_rom[dct_index];

always @(posedge clk)
if(~rst_n) begin
  state <= IDLE;
  rd_en <= 1'b0;
  cnt1 <= 4'd0;
  cnt2 <= 5'd0;
  dct_index <= 9'd0;
  logFBE_l <= 16'd0;
end
else case(state)
IDLE: begin
  if(valid) state <= FIFO_RD;
  else state <= IDLE;
  rd_en <= 1'b0;
  cnt1 <= 4'd0;
  cnt2 <= 5'd0;
  logFBE_l <= 16'd0;
  dct_index <= 9'd0;
end

FIFO_RD: begin
  if(~empty) begin
    state <= HOLD;
    rd_en <= 1'b1;
    cnt2 <= cnt2 + 1'b1;
    dct_index <= dct_index + 1'b1;
    logFBE_l <= logFBE_d;
  end
  else begin
    if(cnt2 == 26) state <= IDLE;
    else state <= FIFO_RD;
  end
  cnt1 <= 4'd0;
end

HOLD: begin
  rd_en <= 1'b0;
  if(cnt1 == 12) begin
    state <= FIFO_RD;
    cnt1 <= 1'b0;
    dct_index <= dct_index;
  end
  else begin
    state <= HOLD;
    cnt1 <= cnt1 + 1'b1;
    dct_index <= dct_index + 1'b1;
  end
end

endcase

assign clear = state == IDLE && valid;
assign mul_ce = state == HOLD;
always @(posedge clk) mul_ce_d <= {mul_ce_d[2:0],mul_ce};
always @(posedge clk)
begin
  cnt_d0 <= cnt1;
  cnt_d1 <= cnt_d0;
  cnt_d2 <= cnt_d1;
  cnt_d3 <= cnt_d2;
  index <= cnt_d3;
end

assign cul_done = state == HOLD && cnt2 == 26;
always @(posedge clk) cul_done_d <= {cul_done_d[3:0],cul_done};

integer i;
always @(posedge clk)
if(~rst_n) begin
  for(i=0;i<13;i=i+1) begin
    hfcc_tmp[i] <= 27'd0;
  end
end else begin
  if(mul_ce_d[2]) begin
    hfcc_tmp[cnt_d2] <= hfcc_tmp[cnt_d2] + fbe_dct_t;
  end else if(clear) begin
    for(i=0;i<13;i=i+1) begin
      hfcc_tmp[i] <= 27'd0;
    end
  end
end

always @(posedge clk)
if(~rst_n) mfcc_tmp <= 16'd0;
else if(cul_done_d[3]) mfcc_tmp <= hfcc_tmp[cnt_d3]>>>5;
else mfcc_tmp <= 16'd0;

assign mfcc_tmp_valid = cul_done_d[4];

mul16x16_signed mul_dct ( //delay 3
  .a(logFBE_l),        // input [15:0]
  .b(dct_data),        // input [15:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(fbe_dct)         // output [31:0]
);


logfbe_buff the_instance_name (
  .wr_data(logFBE),               // input [15:0]
  .wr_en(valid),                  // input
  .rd_data(logFBE_d),             // output [15:0]
  .rd_en(rd_en),                  // input
  .empty(empty),                  // output
  .clk(clk),                      // input
  .rst(~rst_n)                    // input
);

endmodule