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
// Filename:ipm_distributed_shiftregister_v1_2_ipsxe_fft_sreg.v
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module ipsxe_fft_distributed_shiftregister_v1_3
     #(
      parameter  OUT_REG                = 1'b0            ,    //1'b0 or 1'b1
      parameter  FIXED_DEPTH            = 16              ,    //range:1-1024
      parameter  VARIABLE_MAX_DEPTH     = 16              ,    //range:1-1024
      parameter  DATA_WIDTH             = 16              ,    //data width      range:1-256
      parameter  SHIFT_REG_TYPE         = "fixed_latency" ,    //default value :"fixed_latency" or "dynamic_latency"
      parameter  RST_TYPE               = "ASYNC"              //reset type   "ASYNC" "SYNC"

     )
     (
      din ,
      addr,
      clk ,
      clken,
      rst ,
      dout
     );

localparam  DEPTH       = (SHIFT_REG_TYPE=="fixed_latency"  ) ? FIXED_DEPTH :
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
                             //(DEPTH<=512)  ? 9 : 10 

//***********************************************************IO******************************
input   wire  [DATA_WIDTH-1:0]      din        ;
input   wire  [ADDR_WIDTH-1:0]      addr       ;
input   wire                        clk        ;
input   wire                        clken      ;
input   wire                        rst        ;
output  wire  [DATA_WIDTH-1:0]      dout       ;
//*******************************************************************************************
reg           [ADDR_WIDTH-1:0]      wr_addr = {ADDR_WIDTH{1'b0}};
reg           [ADDR_WIDTH-1:0]      rd_addr    ;

wire                                asyn_rst   ;
wire                                syn_rst    ;

assign  asyn_rst  = (RST_TYPE == "ASYNC") ? rst : 0;
assign  syn_rst   = (RST_TYPE == "SYNC" ) ? rst : 0;

generate
    if (RST_TYPE == "ASYNC") begin
        always @(posedge clk or posedge asyn_rst) begin
            if (asyn_rst)
                wr_addr <= 0;
            else if (clken)
                wr_addr <= wr_addr+1;
        end
    end
    else if (RST_TYPE == "SYNC") begin
        always @(posedge clk) begin
            if (syn_rst)
                wr_addr <= 0;
            else if (clken)
                wr_addr <= wr_addr+1;
        end
    end
endgenerate

always @(*) begin
    if (SHIFT_REG_TYPE=="fixed_latency")
        rd_addr = OUT_REG ? (wr_addr+2**ADDR_WIDTH-DEPTH+1) : (wr_addr+2**ADDR_WIDTH-DEPTH);
    else if (SHIFT_REG_TYPE=="dynamic_latency")
        rd_addr = OUT_REG ? (wr_addr+2**ADDR_WIDTH-addr) : (wr_addr+2**ADDR_WIDTH-addr-1);
end

//********************************************************* SDP INST **************************************************
ipsxe_fft_distributed_sdpram_v1_2
 #(
   .ADDR_WIDTH      (ADDR_WIDTH )   ,
   .DATA_WIDTH      (DATA_WIDTH )   ,
   .RST_TYPE        (RST_TYPE   )   ,
   .OUT_REG         (OUT_REG    )   ,
   .INIT_FILE       ("NONE"     )   ,
   .FILE_FORMAT     ("BIN"      )
  ) u_distributed_sdpram
  (
   .wr_data         (din        )   ,
   .wr_addr         (wr_addr    )   ,
   .rd_addr         (rd_addr    )   ,
   .wr_clk          (clk        )   ,
   .rd_clk          (clk        )   ,
   .wr_en           (clken      )   ,
   .rd_en           (clken      )   ,
   .rst             (rst        )   ,
   .rd_data         (dout       )
  );
endmodule

