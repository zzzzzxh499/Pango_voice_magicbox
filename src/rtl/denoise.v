module denoise_u(
    input clk,
    input rst_n,
    input enable,
    output [9:0] ram_addr,
    input  [31:0] ram_data,
    output [31:0] freq_data,
    output reg freq_tlast,
    output reg freq_valid
);

reg [3:0] enable_d;
reg [31:0] data_denoise;
reg [9:0] count;
reg [9:0] freq_index;

always @(posedge clk)
if(~rst_n) enable_d <= 4'd0;
else enable_d <= {enable_d[2:0],enable};

always @(posedge clk)
if(~rst_n) count <= 10'b0;
else if(enable) count <= count + 1'b1;
else count <= 10'b0;

always @(posedge clk)
if(~rst_n) freq_index <= 10'd0;
else if(enable_d[1]) freq_index <= freq_index + 1'b1;
else freq_index <= 10'd0;

always @(posedge clk)
if(~rst_n) freq_valid <= 1'b0;
else if(enable_d[1]&~enable_d[2]) freq_valid <= 1'b1;
else if(freq_tlast) freq_valid <= 1'b0;
else freq_valid <= freq_valid;

always @(posedge clk)
if(~rst_n) freq_tlast <= 1'b0;
else if(enable_d[1] && (&freq_index)) freq_tlast <= 1'b1;
else freq_tlast <= 1'b0;

always @(posedge clk)
if(~rst_n) data_denoise <= 32'd0;
else if(freq_index==10'd43 || freq_index==10'd981) data_denoise <= {ram_data[31],ram_data[31:17],ram_data[15],ram_data[15:1]};//rigth shift
else if(freq_index==10'd51 || freq_index==10'd55 || freq_index==10'd64 || freq_index==10'd66 || freq_index==10'd73 
     || freq_index==10'd973|| freq_index==10'd969|| freq_index==10'd960|| freq_index==10'd958|| freq_index==10'd951 
     || freq_index < 10'd43 || freq_index > 10'd981) data_denoise <= 32'd0;
else data_denoise <= ram_data;

assign ram_addr = count[9:0];
assign freq_data = data_denoise;


endmodule