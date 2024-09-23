module logE ( //system delay 9
	input clk,
  input rst_n,
	input [63 : 0]  i_data,
	output reg [15 : 0]  o_data//fix(16,8)
);
wire [13:0] log2_data;
wire signed [14:0] log2_data_signed = {1'b0,log2_data};
reg signed [15:0] log2_dot;
wire signed [31:0] odata_tmp;

log2 log2( //delay 4 log2(data) fix(14,8) unsigned
	.clk(clk),
	.i_data(i_data),
	.o_data(log2_data)
);

always @(posedge clk) //delay 1
if(~rst_n) log2_dot <= 16'd0;
else log2_dot <= log2_data_signed - 12*256;


MUL16x16 mul_log2E ( //delay 3
  .a(log2_dot),        // input [15:0] round(1/log2(e)*2^15)
  .b(16'h58b9),        // input [15:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(odata_tmp)         // output [31:0]
);

always @(posedge clk) //delay 1
if(~rst_n) o_data <= 16'd0;
else o_data <= odata_tmp>>>15;

endmodule