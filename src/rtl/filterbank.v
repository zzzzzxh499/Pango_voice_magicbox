module filterbank (
    input clk,
    input rst_n,
    input valid,
    input [54:0] fft_sqrs,
    output reg [63:0] fbe,
    output reg fbe_valid);

reg [9:0] lut_addr;
wire [15:0] fbank1,fbank2;
wire [77:0] result1,result2;
reg [77:0] fbe_tmp1,fbe_tmp2;
wire sel1,sel2;
reg [4:0] sel1_d,sel2_d;
wire sel1_change,sel2_change;
reg [2:0] valid_mask;

always @(posedge clk)
if(~rst_n) lut_addr <= 10'd0;
else if(valid) lut_addr <= lut_addr + 1'b1;
else lut_addr <= 10'd0;

always @(posedge clk)
if(~rst_n) sel1_d <= 5'b0;
else sel1_d <= {sel1_d[3:0],sel1};

always @(posedge clk)
if(~rst_n) sel2_d <= 5'b0;
else sel2_d <= {sel2_d[3:0],sel2};

assign sel1_change = sel1_d[4] ^ sel1_d[3];
assign sel2_change = sel2_d[4] ^ sel2_d[3];

always @(*)
if(~rst_n) fbe_tmp1 <= 78'd0;
else if(sel1_change) fbe_tmp1 <= 78'd0;
else fbe_tmp1 <= result1;

always @(*)
if(~rst_n) fbe_tmp2 <= 78'd0;
else if(sel2_change) fbe_tmp2 <= 78'd0;
else fbe_tmp2 <= result2;

always @(posedge clk)
if(~rst_n) fbe <= 64'd0;
else if(sel1_change) fbe <= result1>>13;
else if(sel2_change) fbe <= result2>>13;
else fbe <= 64'd0;

always @(posedge clk)
if(~rst_n) fbe_valid <= 1'b0;
else fbe_valid <= ~valid_mask[2] && (sel1_change || sel2_change);

always @(posedge clk) //ignore first two pos
if(~rst_n) valid_mask <= 3'b111;
else if(valid) begin
  if((sel1_d[3] ^ sel1_d[2]) || (sel2_d[3] ^ sel2_d[2])) valid_mask <= valid_mask << 1;
end else valid_mask <= 3'b111;

mul_add mul_add1(
    .clk(clk),
    .rst_n(rst_n),
    .a(fft_sqrs),
    .b(fbank1),
    .c(fbe_tmp1),
    .p(result1)
);
mul_add mul_add2(
    .clk(clk),
    .rst_n(rst_n),
    .a(fft_sqrs),
    .b(fbank2),
    .c(fbe_tmp2),
    .p(result2)
);


FBANK_LUT1 FBANK_LUT1 (
  .wr_data                  (17'd0              ),    // input [16:0]
  .addr                     (lut_addr           ),    // input [9:0]
  .wr_en                    (1'b0               ),    // input
  .clk                      (clk                ),    // input
  .rst                      (~rst_n             ),    // input
  .rd_data                  ({sel1,fbank1}      )     // output [16:0]
);
FBANK_LUT2 FBANK_LUT2 (
  .wr_data                  (17'd0              ),    // input [16:0]
  .addr                     (lut_addr           ),    // input [9:0]
  .wr_en                    (1'b0               ),    // input
  .clk                      (clk                ),    // input
  .rst                      (~rst_n             ),    // input
  .rd_data                  ({sel2,fbank2}      )     // output [16:0]
);

endmodule