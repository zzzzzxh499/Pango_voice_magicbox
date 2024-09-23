module mfcc_avg
(
    input clk,
    input rst_n,
    input data_valid,
    input mfcc_valid,
    input signed [15:0] mfcc,
    output [15:0] mfcc_means,
    output mfcc_means_valid);

reg data_valid_d0,data_valid_d1;
reg data_valid_t,data_valid_d;
reg mfcc_valid_d,mfcc_valid_d1,mfcc_valid_d2;
wire mfcc_valid_pos = mfcc_valid&&~mfcc_valid_d;
wire mfcc_valid_neg = ~mfcc_valid_d1&&mfcc_valid_d2;

reg signed [25:0] mfcc_mem [16:0];
integer i;
reg [3:0] cnt,cnt_d;
wire [15:0] divlut;
wire signed [25:0] mfcc_sum;
reg mfcc_sum_valid;
wire clear;
wire mfcc_sum_last;
reg [7:0] mfcc_sum_last_d;

reg [9:0] frame_cnt;

wire signed [41:0] mfcc_means_tmp;
wire signed [26:0] mfcc_means_shift;
reg [2:0] mfcc_sum_valid_d;

always @(posedge clk)
if(~rst_n) begin
    data_valid_d0 <= 1'b0;
    data_valid_d1 <= 1'b0;
    data_valid_d <= 1'b0;
end else begin
    data_valid_d0 <= data_valid;
    data_valid_d1 <= data_valid_d0;
    data_valid_d <= data_valid_t;
end

always @(posedge clk)
if(~rst_n) begin
    mfcc_valid_d <= 1'b0;
    mfcc_valid_d1 <= 1'b0;
    mfcc_valid_d2 <= 1'b0;
end
else begin
    mfcc_valid_d <= mfcc_valid;
    mfcc_valid_d1 <= mfcc_valid_d;
    mfcc_valid_d2 <= mfcc_valid_d1;
end

always @(*)
if(~rst_n) data_valid_t <= 1'b0;
else if(~mfcc_valid) data_valid_t <= data_valid_d1; //neg change
else data_valid_t <= data_valid_t;

always @(posedge clk)
if(~rst_n) frame_cnt <= 10'd0;
else if(data_valid_t) begin
    if(mfcc_valid_pos) frame_cnt <= frame_cnt + 1'b1;
    else frame_cnt <= frame_cnt;
end else begin
    if(clear) frame_cnt <= 10'd0;
    else frame_cnt <= frame_cnt;
end

always @(posedge clk)
if(~rst_n) cnt <= 4'd0;
else if(mfcc_valid && data_valid_t) cnt <= cnt + 1'b1;
else cnt <= 4'd0;

always @(posedge clk)
if(~rst_n) begin
    for(i=0;i<16;i=i+1) begin
        mfcc_mem[i] <= 26'd0;
    end
end 
else begin
  if(mfcc_valid && data_valid_t) begin
    mfcc_mem[cnt] <= mfcc_mem[cnt] + mfcc;
  end else if(clear) begin
    for(i=0;i<16;i=i+1) begin
      mfcc_mem[i] <= 26'd0;
    end
  end
end


always @(posedge clk)
if(~rst_n) mfcc_sum_valid <= 1'b0;
else if(data_valid_d && !data_valid_t) mfcc_sum_valid <= 1'b1;
else if(cnt_d == 12) mfcc_sum_valid <= 1'b0;
else mfcc_sum_valid <= mfcc_sum_valid;

always @(posedge clk)
if(~rst_n) cnt_d <= 4'd0;
else if(mfcc_sum_valid) cnt_d <= cnt_d + 1'b1;
else cnt_d <= 4'd0;

always @(posedge clk)
if(~rst_n) mfcc_sum_valid_d <= 3'd0;
else mfcc_sum_valid_d <= {mfcc_sum_valid_d[1:0],mfcc_sum_valid};

assign mfcc_sum = mfcc_mem[cnt_d];

assign mfcc_sum_last = cnt_d==12;

always @(posedge clk) 
if(~rst_n) mfcc_sum_last_d <= 8'd0;
else mfcc_sum_last_d <= {mfcc_sum_last_d[6:0],mfcc_sum_last};

assign clear = mfcc_sum_last_d[7];

div1024 div1024_lut (
  .wr_data(16'd0),    // input [15:0]
  .addr(frame_cnt),          // input [9:0]
  .wr_en(1'b0),        // input
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(divlut)     // output [15:0] 1/frame_cnt*2**15
);

MUL26x16 MUL26x16 (
  .a(mfcc_sum),        // input [25:0]
  .b(divlut),        // input [15:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(mfcc_means_tmp)         // output [41:0]
);

assign mfcc_means_shift = mfcc_means_tmp>>>15;
assign mfcc_means = {mfcc_means_shift[26],mfcc_means_shift[14:0]};
assign mfcc_means_valid = mfcc_sum_valid_d[2];

endmodule