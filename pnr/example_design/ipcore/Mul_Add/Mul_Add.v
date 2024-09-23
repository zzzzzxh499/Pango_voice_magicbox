

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
// Filename: Mul_Add.v                 
//////////////////////////////////////////////////////////////////////////////
module Mul_Add
( 
      ce      ,
      rst     ,
      clk     ,
      a0      ,
      a1      ,
      b0      ,
      b1      ,
     
      addsub  ,
     
      p
);



localparam ASIZE = 16 ; //@IPC int 2,54

localparam BSIZE = 16 ; //@IPC int 2,54

localparam A_SIGNED = 1 ; //@IPC enum 0,1

localparam B_SIGNED = 1 ; //@IPC enum 0,1

localparam ASYNC_RST = 1 ; //@IPC enum 0,1

localparam OPTIMAL_TIMING = 0 ; //@IPC enum 0,1

localparam INREG_EN = 0 ; //@IPC enum 0,1

localparam PIPEREG_EN_1 = 1 ; //@IPC enum 0,1

localparam PIPEREG_EN_2 = 0 ; //@IPC enum 0,1

localparam PIPEREG_EN_3 = 1 ; //@IPC enum 0,1

localparam OUTREG_EN = 0 ; //@IPC enum 0,1

//tmp variable for ipc purpose

localparam PIPE_STATUS = 2 ; //@IPC enum 0,1,2,3,4,5

localparam ASYNC_RST_BOOL = 1 ; //@IPC bool

//end of tmp variable

localparam DYN_ADDSUB_OP = 1 ; //@IPC bool

localparam ADDSUB_OP = 0 ; //@IPC bool

localparam OPTIMAL_TIMING_BOOL = 0 ; //@IPC bool
 

localparam  GRS_EN       = "FALSE"     ;
                                       
localparam  PSIZE = ASIZE + BSIZE +1   ;

input                ce                ;
input                rst               ;
input                clk               ;
input  [ASIZE-1:0]   a0                ;
input  [ASIZE-1:0]   a1                ;
input  [BSIZE-1:0]   b0                ;
input  [BSIZE-1:0]   b1                ;

input                addsub            ;

output [PSIZE-1:0]   p                 ;

wire                 addsub            ;
wire                 addsub_mux        ;

assign addsub_mux = (DYN_ADDSUB_OP == 1) ? addsub : 1'b0;
 
ipml_multadd_v1_1_Mul_Add
#(  
    .ASIZE            ( ASIZE           ),
    .BSIZE            ( BSIZE           ),
    .OPTIMAL_TIMING   ( OPTIMAL_TIMING  ),
    .INREG_EN         ( INREG_EN        ),     
    .PIPEREG_EN_1     ( PIPEREG_EN_1    ),      
    .PIPEREG_EN_2     ( PIPEREG_EN_2    ),
    .PIPEREG_EN_3     ( PIPEREG_EN_3    ),
    .OUTREG_EN        ( OUTREG_EN       ),
    .GRS_EN           ( GRS_EN          ),  
    .A_SIGNED         ( A_SIGNED        ),     
    .B_SIGNED         ( B_SIGNED        ),     
    .ASYNC_RST        ( ASYNC_RST       ),          
    .ADDSUB_OP        ( ADDSUB_OP       ),   
    .DYN_ADDSUB_OP    ( DYN_ADDSUB_OP   )
) u_ipml_multadd_Mul_Add
(
    .ce               ( ce          ),
    .rst              ( rst         ),
    .clk              ( clk         ),
    .a0               ( a0          ),
    .a1               ( a1          ),
    .b0               ( b0          ),
    .b1               ( b1          ),
    .addsub           ( addsub_mux  ),     
    .p                ( p           )
);
endmodule

