module multiple_sum( //delay 6
    a,
    b,
    clk,
    rst,
    ce,
    p
);
parameter WIDTH = 16;
parameter NUM_INPUTS = 20;

input wire signed [WIDTH*NUM_INPUTS-1:0] a;
input wire signed [WIDTH*NUM_INPUTS-1:0] b;
input clk;
input rst;
input ce;
output wire signed [36:0] p;

wire signed [32:0] p_n [NUM_INPUTS/2-1:0];
reg signed [34:0] reg1,reg2,reg3;
reg signed [36:0] y_tmp;

genvar j;
generate
for(j=0;j<NUM_INPUTS/2;j=j+1) begin:mul_add
    Mul_Add Mul_Add (
    .a0(a[2*j*WIDTH+:WIDTH]),            // input [15:0]
    .a1(a[2*j*WIDTH+WIDTH+:WIDTH]),            // input [15:0]
    .b0(b[2*j*WIDTH+:WIDTH]),            // input [15:0]
    .b1(b[2*j*WIDTH+WIDTH+:WIDTH]),            // input [15:0]
    .clk(clk),          // input
    .rst(rst),          // input
    .ce(ce),            // input
    .addsub(1'b0),    // input
    .p(p_n[j])               // output [32:0]
    );
end
endgenerate

always @(posedge clk)
if(rst) begin
    reg1 <= 35'd0;
    reg2 <= 35'd0;
    reg3 <= 35'd0;
    y_tmp <= 37'd0;
end else if(ce) begin
    reg1 <= (p_n[0] + p_n[1]) + (p_n[2] + p_n[3]);
    reg2 <= (p_n[4] + p_n[5]) + (p_n[6] + p_n[7]);
    reg3 <= (p_n[8] + p_n[9]);
    y_tmp <= reg1 + reg2 + reg3;
end

assign p = y_tmp;
endmodule