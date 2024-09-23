module lifter(
    input clk,
    input rst_n,
    input [15:0] mfcc_tmp,
    input mfcc_tmp_valid,
    input [3:0] index,
    output [15:0] mfcc,
    output mfcc_valid
);

wire signed [15:0] lifter_rom [12:0];
wire [15:0] lifter_data;
wire signed [31:0] result;
reg [2:0] valid_d;

always @(posedge clk) valid_d <= {valid_d[1:0],mfcc_tmp_valid};

assign mfcc = result >>> 10;
assign mfcc_valid = valid_d[2];


assign  lifter_rom[00] = 16'h0400;
assign  lifter_rom[01] = 16'h0A43;
assign  lifter_rom[02] = 16'h1065;
assign  lifter_rom[03] = 16'h1647;
assign  lifter_rom[04] = 16'h1BCA;
assign  lifter_rom[05] = 16'h20D0; 
assign  lifter_rom[06] = 16'h2541;
assign  lifter_rom[07] = 16'h2904;
assign  lifter_rom[08] = 16'h2C06;
assign  lifter_rom[09] = 16'h2E38;
assign  lifter_rom[10] = 16'h2F8D;
assign  lifter_rom[11] = 16'h3000; 
assign  lifter_rom[12] = 16'h2F8D; 


assign lifter_data = lifter_rom[index];

MUL16x16 mul_log2E ( //delay 3
  .a(mfcc_tmp),        // input [15:0]
  .b(lifter_data),        // input [15:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(result)         // output [31:0]
);


endmodule