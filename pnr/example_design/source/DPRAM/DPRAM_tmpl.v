// Created by IP Generator (Version 2022.2-SP1-Lite build 132640)
// Instantiation Template
//
// Insert the following codes into your Verilog file.
//   * Change the_instance_name to your own instance name.
//   * Change the signal names in the port associations


DPRAM the_instance_name (
  .a_addr(a_addr),          // input [9:0]
  .a_wr_data(a_wr_data),    // input [17:0]
  .a_rd_data(a_rd_data),    // output [17:0]
  .a_wr_en(a_wr_en),        // input
  .a_clk(a_clk),            // input
  .a_rst(a_rst),            // input
  .b_addr(b_addr),          // input [9:0]
  .b_wr_data(b_wr_data),    // input [17:0]
  .b_rd_data(b_rd_data),    // output [17:0]
  .b_wr_en(b_wr_en),        // input
  .b_clk(b_clk),            // input
  .b_rst(b_rst)             // input
);
