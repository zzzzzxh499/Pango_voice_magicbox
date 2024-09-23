// Created by IP Generator (Version 2021.1-SP6.4 build 84837)



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
// Filename:ipsxe_fft_sreg.v
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module ipsxe_fft_distram_sreg
     (
      din       ,      
      clk       ,
      clken     ,
      rst       ,
      dout
     );

    localparam OUT_REG = 1 ; //@IPC bool

    parameter  FIXED_DEPTH = 4 ; // @IPC int 1,1024

    localparam VARIABLE_MAX_DEPTH = 14 ; // @IPC int 1,1024

    parameter  DATA_WIDTH = 10 ; // @IPC int 1,256

    localparam SHIFT_REG_TYPE = "fixed_latency" ; // @IPC enum fixed_latency,dynamic_latency

    localparam SHIFT_REG_TYPE_BOOL = 1 ; // @IPC bool

    localparam RST_TYPE = "ASYNC" ; // @IPC enum ASYNC,SYNC


    localparam  DEPTH   = (SHIFT_REG_TYPE=="fixed_latency"  ) ? FIXED_DEPTH :
                          (SHIFT_REG_TYPE=="dynamic_latency") ? VARIABLE_MAX_DEPTH : 0;

    
    function integer clog2;
    input integer n;
    begin
        n = n - 1;
        for (clog2=0; n>0; clog2=clog2+1)
            n = n >> 1;
    end
    endfunction
    
    localparam  ADDR_WIDTH = (DEPTH<=16)   ? 4 : clog2(DEPTH);
                             //(DEPTH<=32)   ? 5 :
                             //(DEPTH<=64)   ? 6 :
                             //(DEPTH<=128)  ? 7 :
                             //(DEPTH<=256)  ? 8 :
                             //(DEPTH<=512)  ? 9 : 10 ;


     input  wire     [DATA_WIDTH-1:0]       din     ;
      
     input  wire                            clk     ;
     input  wire                            clken   ;
     input  wire                            rst     ;
     output wire     [DATA_WIDTH-1:0]       dout    ;


ipsxe_fft_distributed_shiftregister_v1_3
   #(
    .OUT_REG             (OUT_REG            )  ,
    .FIXED_DEPTH         (FIXED_DEPTH        )  ,
    .VARIABLE_MAX_DEPTH  (VARIABLE_MAX_DEPTH )  ,
    .DATA_WIDTH          (DATA_WIDTH         )  ,
    .SHIFT_REG_TYPE      (SHIFT_REG_TYPE     )  ,
    .RST_TYPE            (RST_TYPE           )
    ) u_distributed_shiftregister
    (
    .din                 (din                )  ,
    
    .addr                ({ADDR_WIDTH{1'b0}} )  ,
        
    .clk                 (clk                )  ,
    .clken               (clken              )  ,
    .rst                 (rst                )  ,
    .dout                (dout               )
    );
endmodule
