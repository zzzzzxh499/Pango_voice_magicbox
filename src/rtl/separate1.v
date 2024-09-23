module separate1_u(
    input clk,
    input rst_n,
    input separate1,
    input enable,
    output reg [9:0] ram_addr,
    input  [31:0] ram_data,
    output reg [31:0] freq_data,
    output reg freq_tlast,
    output reg freq_valid,
    output debug
);


reg [3:0] enable_d;
wire enable_neg;
always @(posedge clk)
if(~rst_n) enable_d <= 4'd0;
else enable_d <= {enable_d[2:0],enable};

assign enable_neg = enable_d[3] & ~enable_d[2];

/// state machine
localparam IDLE = 3'd0,WAITING = 3'd1,LEARNING = 3'd2,SEPARATE = 3'd3;
`ifdef SIMULATION
localparam N = 30-1;
`else
localparam N = 85;
`endif
reg [2:0] state;
reg [6:0] frame_cnt;
reg [15:0] compare_result;
wire lut_wren;
wire [15:0] abs_data;
wire [15:0] abs_lut;
wire [15:0] lut_data;
reg data_valid;
assign abs_data = (ram_data[15] == 1'b1)?(~ram_data[15:0] + 1'b1):ram_data[15:0];
assign abs_lut = (lut_data[15] == 1'b1)?(~lut_data[15:0] + 1'b1):lut_data[15:0];
assign debug = state==SEPARATE;

always @(posedge clk)
if(~rst_n) compare_result <= 32'd0;
else if(frame_cnt == N-1) begin
  if(abs_data>abs_lut) compare_result <= abs_data + (abs_data>>2);
  else compare_result <= abs_lut + (abs_lut>>2);
end
else begin
  if(abs_data>abs_lut) compare_result <= abs_data;
  else compare_result <= abs_lut;
end

always @(posedge clk)
if(~rst_n) state <= IDLE;
else case(state) 
IDLE: if(separate1) state <= WAITING;
WAITING: if(data_valid&&enable_neg) state <= LEARNING;
LEARNING: if(frame_cnt==N) state <= SEPARATE;
SEPARATE: if(~separate1) state <= IDLE;
endcase

always @(posedge clk)
if(~rst_n) frame_cnt <= 7'd0;
else if(state==LEARNING) begin if(enable_neg) frame_cnt <= frame_cnt + 1'b1; end
else frame_cnt <= 7'd0;

assign lut_wren = (state==LEARNING) & enable_d[2];

always @(posedge clk)
if(~rst_n) data_valid <= 1'b0;
else if(state==WAITING) begin if(ram_data > 16'd1) data_valid <= 1'b1; end
else data_valid <= 1'b0;



reg [9:0] freq_index;
wire [15:0] door;
reg [9:0] ram_addr_d2;

assign door = lut_data;

always @(posedge clk)
if(~rst_n) ram_addr <= 10'b0;
else if(enable) ram_addr <= ram_addr + 1'b1;
else ram_addr <= 10'b0;

always @(posedge clk)
if(~rst_n) ram_addr_d2 <= 10'b0;
else if(enable_d[2]) ram_addr_d2 <= ram_addr_d2 + 1'b1;
else ram_addr_d2 <= 10'b0;

always @(posedge clk)
if(~rst_n) freq_data <= 32'd0;
else if(state==LEARNING) freq_data <= 32'd0;
else if(state==SEPARATE) freq_data <= abs_data>door?ram_data:32'd0;
else freq_data <= 32'd0;


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


Sperate_door Sperate_door (
  .wr_data      (compare_result),    // input [16:0]
  .wr_addr      (ram_addr_d2),    // input [9:0]
  .wr_en        (lut_wren),        // input
  .wr_clk       (clk),      // input
  .wr_rst       (~separate1),      // input
  .rd_addr      (ram_addr),    // input [9:0]
  .rd_data      (lut_data),    // output [16:0]
  .rd_clk       (clk),      // input
  .rd_rst       (~separate1)       // input
);

endmodule