module sync_fifo(
    clk     ,
    rst     ,
    wr_en   ,
    wr_data ,
    rd_en   ,
    rd_data 
);
input clk;
input rst;
input wr_en;
input [15:0] wr_data;
input rd_en;
output [15:0] rd_data;

reg [8:0] addr;

always @(posedge clk)
if(rst) addr <= 9'd0;
else if(wr_en || rd_en) addr <= addr + 1'b1;
else addr <= 9'd0;

HANN_RAM HANN_RAM (
  .wr_data(wr_data),    // input [15:0]
  .addr(addr),          // input [8:0]
  .clk(clk),            // input
  .wr_en(wr_en),        // input
  .rst(rst),            // input
  .rd_data(rd_data)     // output [15:0]
);

endmodule