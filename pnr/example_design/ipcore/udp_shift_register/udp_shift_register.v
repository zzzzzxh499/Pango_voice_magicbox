

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
// Filename:udp_shift_register.v
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
module udp_shift_register
     (
      din       ,
      
      clk       ,
      rst       ,
      dout
     );

    localparam OUT_REG = 0 ; //@IPC bool

    localparam FIXED_DEPTH = 8 ; // @IPC int 1,1024

    localparam VARIABLE_MAX_DEPTH = 4 ; // @IPC int 1,1024

    localparam DATA_WIDTH = 8 ; // @IPC int 1,256

    localparam SHIFT_REG_TYPE = "fixed_latency" ; // @IPC enum fixed_latency,dynamic_latency

    localparam SHIFT_REG_TYPE_BOOL = 0 ; // @IPC bool

    localparam RST_TYPE = "ASYNC" ; // @IPC enum ASYNC,SYNC


    localparam  DEPTH   = (SHIFT_REG_TYPE=="fixed_latency"  ) ? FIXED_DEPTH :
                          (SHIFT_REG_TYPE=="dynamic_latency") ? VARIABLE_MAX_DEPTH : 0;


    localparam  ADDR_WIDTH = (DEPTH<=16)   ? 4 :
                             (DEPTH<=32)   ? 5 :
                             (DEPTH<=64)   ? 6 :
                             (DEPTH<=128)  ? 7 :
                             (DEPTH<=256)  ? 8 :
                             (DEPTH<=512)  ? 9 : 10 ;


     input  wire     [DATA_WIDTH-1:0]       din     ;
     
     input  wire                            clk     ;
     input  wire                            rst     ;
     output wire     [DATA_WIDTH-1:0]       dout    ;


ipm_distributed_shiftregister_v1_3_udp_shift_register
   #(
    .OUT_REG             (OUT_REG            )  ,
    .FIXED_DEPTH         (FIXED_DEPTH        )  ,
    .VARIABLE_MAX_DEPTH  (VARIABLE_MAX_DEPTH )  ,
    .DATA_WIDTH          (DATA_WIDTH         )  ,
    .SHIFT_REG_TYPE      (SHIFT_REG_TYPE     )  ,
    .RST_TYPE            (RST_TYPE           )
    )u_ipm_distributed_shiftregister_udp_shift_register
    (
    .din                 (din                )  ,
    
    .addr                ({ADDR_WIDTH{1'b0}} )  ,
        
    .clk                 (clk                )  ,
    .rst                 (rst                )  ,
    .dout                (dout               )
    );
endmodule
