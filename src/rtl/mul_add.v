module mul_add(
    input clk,
    input rst_n,
    input [54:0] a,
    input [15:0] b,
    input [77:0] c,
    output reg [77:0] p
);
wire [70:0] axb;

always @(posedge clk)
if(~rst_n) begin
    p <= 78'd0;
end else begin
    p <= c + axb;
end

mul55x16 mul55x16 (
  .a(a),        // input [54:0]
  .b(b),        // input [15:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(axb)         // output [70:0]
);


endmodule