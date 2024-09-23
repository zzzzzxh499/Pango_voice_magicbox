module Squares(
    input clk,
    input rst_n,
    input signed [26:0] a,b,
    output reg [54:0] c
);

reg [53:0] a2,b2;
reg [53:0] a2_d,a2_dd;
reg [53:0] b2_d,b2_dd;

always @(posedge clk)
if(~rst_n) begin
    a2 <= 54'd0;
    b2 <= 54'd0;
end else begin
    a2 <= a * a;
    b2 <= b * b;
end

always @(posedge clk)
if(~rst_n) begin
    a2_d <= 54'd0;
    a2_dd <= 54'd0;
    b2_d <= 54'd0;
    b2_dd <= 54'd0;
end else begin
    a2_d <= a2;
    a2_dd <= a2_d;
    b2_d <= b2;
    b2_dd <= b2_d;
end

always @(posedge clk)
if(~rst_n) begin
    c <= 55'd0;
end else begin
    c <= a2_dd + b2_dd;
end

endmodule