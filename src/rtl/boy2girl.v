module boy2girl_u(
    input clk,
    input rst_n,
    input enable,
    output [9:0] ram_addr,
    input  [31:0] ram_data,
    output reg [31:0] freq_data,
    output reg freq_tlast,
    output reg freq_valid
);

reg [3:0] enable_d;
reg [9:0] freq_index;
reg [9:0] cnt;
wire [15:0] ram_addr_tmp; 
reg set2zero;

always @(posedge clk)
if(~rst_n) enable_d <= 4'd0;
else enable_d <= {enable_d[2:0],enable};

always @(posedge clk)
if(~rst_n) cnt <= 10'd0;
else if(enable) cnt <= cnt + 1'b1;
else cnt <= 10'd0;

always @(posedge clk)
if(~rst_n) freq_index <= 10'd0;
else if(enable_d[2]) freq_index <= freq_index + 1'b1;
else freq_index <= 10'd0;

always @(posedge clk)
if(~rst_n) freq_valid <= 1'b0;
else if(enable_d[2]&~enable_d[3]) freq_valid <= 1'b1;
else if(freq_tlast) freq_valid <= 1'b0;
else freq_valid <= freq_valid;

always @(posedge clk)
if(~rst_n) freq_tlast <= 1'b0;
else if(enable_d[2] && (&freq_index)) freq_tlast <= 1'b1;
else freq_tlast <= 1'b0;


always @(posedge clk)
if(~rst_n) freq_data <= 32'd0;
else if(~set2zero) freq_data <= ram_data;
else freq_data <= 32'd0;

LUT_2GIRL LUT_2GIRL (
  .wr_data(10'd0),    // input [15:0]
  .addr(cnt),          // input [9:0]
  .wr_en(1'b0),        // input
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(ram_addr_tmp)     // output [15:0]
);

assign ram_addr = ram_addr_tmp[9:0];

always @(posedge clk)
if(~rst_n) set2zero <= 1'b0;
else set2zero <= &ram_addr_tmp;

endmodule