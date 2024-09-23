module round_signed #(
    parameter WIDTH_IN = 32, 
    parameter WIDTH_OUT = 32, 
    parameter SHIFT = 4
) (
    input signed [WIDTH_IN-1:0] in,  // 输入信号
    output signed [WIDTH_OUT-1:0] out // 输出信号
);
    reg signed [WIDTH_IN-1:0] rounded;
    
    always @(*) begin
        // 检查是否需要四舍五入
        if (SHIFT > 0) begin
            // 四舍五入公式
            rounded = (in + (1 << (SHIFT - 1))) >>> SHIFT;
        end else begin
            // 不需要四舍五入
            rounded = in;
        end
    end

    assign out = rounded[WIDTH_OUT-1:0];

endmodule
