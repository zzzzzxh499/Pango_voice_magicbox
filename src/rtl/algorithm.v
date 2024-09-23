module algorithm(
    input clk,
    input rst_n,
    input enable,
    input boy2girl,
    input girl2boy,
    input denoise,
    input separate1,
    input separate2,
    output reg [9:0] ram_addr,
    input  [31:0] ram_data,
    output reg [31:0] freq_data,
    output reg freq_tlast,
    output reg freq_valid,
    output debug
);


reg girl2boy_d0;
reg girl2boy_d1;
reg boy2girl_d0;
reg boy2girl_d1;
reg denoise_d0;
reg denoise_d1;
reg separate1_d0;
reg separate1_d1;
reg separate2_d0;
reg separate2_d1;
reg [3:0] enable_d;
wire signal_change;
reg [31:0] ram_data_d0;
wire [31:0] data_denoise,data_boy2girl,data_girl2boy;
wire [31:0] data_separate1,data_separate2;
wire [9:0] addr_girl2boy,addr_denoise,addr_boy2girl;
wire [9:0] addr_separate1,addr_separate2;
reg [9:0] count;
reg ram_data_valid;
reg ram_data_tlast;
wire valid_boy2girl,valid_girl2boy;
wire valid_denoise,valid_separate1,valid_separate2;
wire last_boy2girl,last_girl2boy;
wire last_denoise,last_separate1,last_separate2;
reg [9:0] freq_index;

girl2boy_u girl2boy_u (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .enable                 (enable&&girl2boy_d1),
    .ram_addr               (addr_girl2boy),
    .ram_data               (ram_data),
    .freq_data              (data_girl2boy),
    .freq_valid             (valid_girl2boy),
    .freq_tlast             (last_girl2boy)
);

boy2girl_u boy2girl_u (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .enable                 (enable&&boy2girl_d1),
    .ram_addr               (addr_boy2girl),
    .ram_data               (ram_data),
    .freq_data              (data_boy2girl),
    .freq_valid             (valid_boy2girl),
    .freq_tlast             (last_boy2girl)
);

denoise_u denoise_u (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .enable                 (enable&&denoise_d1),
    .ram_addr               (addr_denoise),
    .ram_data               (ram_data),
    .freq_data              (data_denoise),
    .freq_valid             (valid_denoise),
    .freq_tlast             (last_denoise)
);

separate1_u separate1_u (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .separate1              (separate1_d1),
    .enable                 (enable&&separate1_d1),
    .ram_addr               (addr_separate1),
    .ram_data               (ram_data),
    .freq_data              (data_separate1),
    .freq_valid             (valid_separate1),
    .freq_tlast             (last_separate1),
    .debug                  (debug)
);

separate2_u separate2_u (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .enable                 (enable&&separate2_d1),
    .ram_addr               (addr_separate2),
    .ram_data               (ram_data),
    .freq_data              (data_separate2),
    .freq_valid             (valid_separate2),
    .freq_tlast             (last_separate2)
);

always @(posedge clk)
if(~rst_n) enable_d <= 4'd0;
else enable_d <= {enable_d[2:0],enable};
assign signal_change = ~(enable_d[3] | enable);

// sync
always @(posedge clk)
if(~rst_n) girl2boy_d0 <= 10'd0;
else girl2boy_d0 <= girl2boy;
always @(posedge clk)
if(~rst_n) girl2boy_d1 <= 10'd0;
else girl2boy_d1 <= signal_change ? girl2boy_d0 : girl2boy_d1; //使用中锁存
always @(posedge clk)
if(~rst_n) boy2girl_d0 <= 10'd0;
else boy2girl_d0 <= boy2girl;
always @(posedge clk)
if(~rst_n) boy2girl_d1 <= 10'd0;
else boy2girl_d1 <= signal_change ? boy2girl_d0 : boy2girl_d1; //使用中锁存
always @(posedge clk)
if(~rst_n) denoise_d0 <= 10'd0;
else denoise_d0 <= denoise;
always @(posedge clk)
if(~rst_n) denoise_d1 <= 10'd0;
else denoise_d1 <= signal_change ? denoise_d0 : denoise_d1; //使用中锁存
always @(posedge clk)
if(~rst_n) separate2_d0 <= 10'd0;
else separate2_d0 <= separate2;
always @(posedge clk)
if(~rst_n) separate2_d1 <= 10'd0;
else separate2_d1 <= signal_change ? separate2_d0 : separate2_d1; //使用中锁存
always @(posedge clk)
if(~rst_n) separate1_d0 <= 10'd0;
else separate1_d0 <= separate1;
always @(posedge clk)
if(~rst_n) separate1_d1 <= 10'd0;
else separate1_d1 <= signal_change ? separate1_d0 : separate1_d1; //使用中锁存

always @(posedge clk)
if(~rst_n) count <= 10'b0;
else if(enable) count <= count + 1'b1;
else count <= 10'b0;

always @(posedge clk)
if(~rst_n) freq_index <= 10'd0;
else if(enable_d[1]) freq_index <= freq_index + 1'b1;
else freq_index <= 10'd0;

always @(posedge clk)
if(~rst_n) ram_data_valid <= 1'b0;
else if(enable_d[1]&~enable_d[2]) ram_data_valid <= 1'b1;
else if(ram_data_tlast) ram_data_valid <= 1'b0;
else ram_data_valid <= ram_data_valid;

always @(posedge clk)
if(~rst_n) ram_data_tlast <= 1'b0;
else if(enable_d[1] && (&freq_index)) ram_data_tlast <= 1'b1;
else ram_data_tlast <= 1'b0;

always @(posedge clk)
if(~rst_n) ram_data_d0 <= 32'd0;
else ram_data_d0 <= ram_data;


always @(posedge clk)
if(~rst_n) begin
    ram_addr = 10'd0;
    freq_data = 32'd0;
    freq_valid = 1'b0;
    freq_tlast = 1'b0;
end
else case({girl2boy_d1,boy2girl_d1,denoise_d1,separate1_d1,separate2_d1})
5'b10000:begin
    ram_addr = addr_girl2boy;
    freq_data = data_girl2boy;
    freq_valid = valid_girl2boy;
    freq_tlast = last_girl2boy;
end
5'b01000:begin
    ram_addr = addr_boy2girl;
    freq_data = data_boy2girl;
    freq_valid = valid_boy2girl;
    freq_tlast = last_boy2girl;
end
5'b00100:begin
    ram_addr = addr_denoise;
    freq_data = data_denoise;
    freq_valid = valid_denoise;
    freq_tlast = last_denoise;
end
5'b00010:begin
    ram_addr = addr_separate1;
    freq_data = data_separate1;
    freq_valid = valid_separate1;
    freq_tlast = last_separate1;
end
5'b00001:begin
    ram_addr = addr_separate2;
    freq_data = data_separate2;
    freq_valid = valid_separate2;
    freq_tlast = last_separate2;
end
default:begin
    ram_addr = count[9:0];
    freq_data = ram_data_d0;
    freq_valid = ram_data_valid;
    freq_tlast = ram_data_tlast;
end
endcase

endmodule