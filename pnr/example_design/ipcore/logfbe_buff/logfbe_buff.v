
//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2014 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:logfbe_buff.v
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
module logfbe_buff
 (
  wr_data         ,
  wr_en           ,
  
  full            ,
  almost_full     ,
  
  rd_data         ,
  rd_en           ,
  
  empty           ,
  
  clk             ,
  rst             ,
  
  almost_empty
);

    localparam ADDR_WIDTH = 5 ; //@IPC int 4,10

    localparam DATA_WIDTH = 16 ; //@IPC int 1,256

    localparam OUT_REG = 0 ; //@IPC bool

    localparam RST_TYPE = "ASYNC" ; //@IPC enum ASYNC,SYNC

    localparam FIFO_TYPE = "SYNC_FIFO" ; //@IPC enum ASYNC_FIFO,SYNC_FIFO

    localparam ALMOST_FULL_NUM = 26 ; //@IPC int 4,1024

    localparam ALMOST_EMPTY_NUM = 4 ; //@IPC int 4,1024

    localparam WR_WATER_LEVEL_ENABLE = 0 ; //@IPC bool

    localparam RD_WATER_LEVEL_ENABLE = 0 ; //@IPC bool

    input  wire                          clk             ;  // sync fifo clock
    input  wire                          rst             ;  // sync fifo rst
    
    input  wire  [DATA_WIDTH-1 : 0]      wr_data         ;  // input write data
    input  wire                          wr_en           ;  // input write enable 1 active
    
    output wire                          full            ;  // input write full  flag 1 active
    output wire                          almost_full     ;  // output write almost full
    

    output wire  [DATA_WIDTH-1 : 0]      rd_data         ;  // output read data
    input  wire                          rd_en           ;  // input  read enable
    
    output wire                          empty           ;  // output read empty
    output wire                          almost_empty    ;  // output read water level
    

ipm_distributed_fifo_v1_2_logfbe_buff
 #(
  .ADDR_WIDTH       (ADDR_WIDTH      ) ,  // fifo ADDR_WIDTH width 4 -- 10
  .DATA_WIDTH       (DATA_WIDTH      ) ,  // write data width 4 -- 256
  .OUT_REG          (OUT_REG         ) ,  // output register   legal value:0 or 1
  .RST_TYPE         (RST_TYPE        ) ,
  .FIFO_TYPE        (FIFO_TYPE       ) ,  // fifo type legal value "SYN" or "ASYN"
  .ALMOST_FULL_NUM  (ALMOST_FULL_NUM ) ,  // almost full number
  .ALMOST_EMPTY_NUM (ALMOST_EMPTY_NUM)    // almost full number
)u_ipm_distributed_fifo_logfbe_buff
 (
  .wr_data          (wr_data         ) ,  // input write data
  .wr_en            (wr_en           ) ,  // input write enable 1 active
  
  .wr_clk           (clk             ) ,  // input write clock
  .wr_rst           (rst             ) ,
  
  .full             (full            ) ,  // input write full  flag 1 active
  .almost_full      (almost_full     ) ,  // output write almost full
  
  .rd_data          (rd_data         ) ,  // output read data
  .rd_en            (rd_en           ) ,  // input  read enable
  
  .rd_clk           (clk             ) ,  // input  read clock
  .rd_rst           (rst             ) ,
  
  .empty            (empty           ) ,  // output read empty
  
  .almost_empty     (almost_empty    )
);
endmodule
