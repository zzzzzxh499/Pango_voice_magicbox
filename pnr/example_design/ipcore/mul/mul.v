
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
// Filename: mul.v
//////////////////////////////////////////////////////////////////////////////
module mul
(
     ce  ,
     rst ,
     clk ,
     a   ,
     b   ,
     p
);



localparam ASIZE = 16 ; //@IPC int 2,72

localparam BSIZE = 16 ; //@IPC int 2,72

localparam A_SIGNED = 1 ; //@IPC enum 0,1

localparam B_SIGNED = 1 ; //@IPC enum 0,1

localparam ASYNC_RST = 1 ; //@IPC enum 0,1

localparam OPTIMAL_TIMING = 0 ; //@IPC enum 0,1

localparam INREG_EN = 0 ; //@IPC enum 0,1

localparam PIPEREG_EN_1 = 1 ; //@IPC enum 0,1

localparam PIPEREG_EN_2 = 1 ; //@IPC enum 0,1

localparam PIPEREG_EN_3 = 1 ; //@IPC enum 0,1

localparam OUTREG_EN = 0 ; //@IPC enum 0,1

//tmp variable for ipc purpose

localparam PIPE_STATUS = 3 ; //@IPC enum 0,1,2,3,4,5

localparam ASYNC_RST_BOOL = 1 ; //@IPC bool

localparam OPTIMAL_TIMING_BOOL = 0 ; //@IPC bool

//end of tmp variable
localparam  GRS_EN       = "FALSE"         ;

localparam  PSIZE = ASIZE + BSIZE          ;

input                 ce  ;
input                 rst ;
input                 clk ;
input  [ASIZE-1:0]    a   ;
input  [BSIZE-1:0]    b   ;
output [PSIZE-1:0]    p   ;

ipml_mult_v1_2_mul
    #(
    .ASIZE           ( ASIZE            ),
    .BSIZE           ( BSIZE            ),
    .OPTIMAL_TIMING  ( OPTIMAL_TIMING   ),
    .INREG_EN        ( INREG_EN         ),
    .PIPEREG_EN_1    ( PIPEREG_EN_1     ),
    .PIPEREG_EN_2    ( PIPEREG_EN_2     ),
    .PIPEREG_EN_3    ( PIPEREG_EN_3     ),
    .OUTREG_EN       ( OUTREG_EN        ),
    .GRS_EN          ( GRS_EN           ),
    .A_SIGNED        ( A_SIGNED         ),
    .B_SIGNED        ( B_SIGNED         ),
    .ASYNC_RST       ( ASYNC_RST        )
    )u_ipml_mult_mul
    (
    .ce              ( ce     ),
    .rst             ( rst    ),
    .clk             ( clk    ),
    .a               ( a      ),
    .b               ( b      ),
    .p               ( p      )
    );

endmodule

