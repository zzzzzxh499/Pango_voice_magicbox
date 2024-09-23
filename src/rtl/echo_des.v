module echo_des (
    clk,
    rst_n,
    enable,
    echo_data,
    exp_data,
    valid,
    data_out
); 
parameter N = 20; // 滤波器长度
parameter MU = 7; // 2^-7 步长因子

input clk;
input rst_n;
input enable;
input signed [15:0] echo_data;
input signed [15:0] exp_data;
input valid;
output reg signed [15:0] data_out;

reg signed [15:0] x,x_echo;
reg signed [15:0] h [N-1:0]; // 滤波器系数 16bit定点小数 signed
reg signed [15:0] x_n [N-1:0]; // 卷积滑窗区域
reg signed [15:0] y_n; // 卷积结果
wire signed [32:0] net0 [N/2-1:0]; // 中间乘法结果
reg signed [34:0] reg1,reg2,reg3; // 加法中间结果
reg signed [36:0] y_tmp; // 卷积结果
wire signed [31:0] delt_tmp [N-1:0];
wire signed [31:0] tmpt [N-1:0];
wire signed [15:0] delt [N-1:0];
reg signed [15:0] e_n;
reg [4:0] delay;
integer i;

always @(posedge clk)
if(~rst_n) delay <= 5'd0;
else if(valid) delay <= 5'd0;
else delay <= &delay ? delay : delay + 1'd1;

always @(posedge clk)
if(~rst_n) begin
    x <= 16'd0;
    x_echo <= 16'd0;
end else if(valid) begin
    x <= exp_data;
    x_echo <= echo_data;
end

// 设置卷积滑窗
always @(posedge clk)
if(~rst_n) begin
    for(i=0;i<N;i=i+1) begin
        x_n[i] <= 'd0;
    end
end else if(enable) begin
    if(valid) begin
        x_n[N-1] <= x_echo;
        for(i=0;i<N-1;i=i+1) begin : xn
            x_n[i] <= x_n[i+1];
        end
    end
end
else begin
    for(i=0;i<N;i=i+1) begin
        x_n[i] <= 'd0;
    end
end

always @(posedge clk)
if(~rst_n) y_n <= 16'd0;
else if(delay == 5'd6) y_n <= y_tmp>>>15;
else y_n <= y_n;

always @(posedge clk)
if(~rst_n) e_n <= 16'd0;
else if(delay == 5'd7) e_n <= x - y_n;
else e_n <= e_n;


always @(posedge clk)
if(~rst_n) begin
    for(i=0;i<N;i=i+1) begin
        h[i] <= 'd0;
    end
end 
else if(enable) begin
    if(delay == 5'd12) begin
        for(i=0;i<N;i=i+1) begin
            h[i] <= h[i] + delt[i];
        end
    end
end else begin
    for(i=0;i<N;i=i+1) begin
        h[i] <= 'd0;
    end
end

genvar j;

//sum xi*hi
generate
for(j=0;j<N/2;j=j+1) begin:mul_add  
    Mul_Add Mul_Add (
    .a0(x_n[2*j]),            // input [15:0]
    .a1(x_n[2*j+1]),            // input [15:0]
    .b0(h[2*j]),            // input [15:0]
    .b1(h[2*j+1]),            // input [15:0]
    .clk(clk),          // input
    .rst(~rst_n),          // input
    .ce(enable),            // input
    .addsub(1'b0),    // input
    .p(net0[j])               // output [32:0]
    );
end
endgenerate

always @(posedge clk)
if(~rst_n) begin
    reg1 <= 35'd0;
    reg2 <= 35'd0;
    reg3 <= 35'd0;
    y_tmp <= 37'd0;
end else begin
    reg1 <= (net0[0] + net0[1]) + (net0[2] + net0[3]);
    reg2 <= (net0[4] + net0[5]) + (net0[6] + net0[7]);
    reg3 <= (net0[8] + net0[9]);
    y_tmp <= reg1 + reg2 + reg3;
end


generate
for(j=0;j<N;j=j+1) begin
    mul mul_ex (
    .a(e_n),        // input [15:0]
    .b(x_n[j]),        // input [15:0]
    .clk(clk),    // input
    .rst(~rst_n),    // input
    .ce(enable),      // input
    .p(delt_tmp[j])         // output [31:0]
    );
    round_signed #(32,16,21) delt_20 (.in(delt_tmp[j]),  .out(delt[j]));
end
endgenerate

always @(posedge clk)
if(~rst_n) data_out <= 'd0;
else if(valid) data_out <= y_n;
else data_out <= data_out;



endmodule