

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
// Filename:TB udp_shift_register_tb.v
//////////////////////////////////////////////////////////////////////////////

`timescale   1ns / 1ps

module  udp_shift_register_tb ();

    localparam T_CLK_PERIOD = 10  ;       //clock a half perid
    localparam T_RST_TIME   = 200 ;       //reset time     

    localparam FIXED_DEPTH = 8 ; // @IPC int 1,1024

    localparam VARIABLE_MAX_DEPTH = 4 ; // @IPC int 1,1024

    localparam DATA_WIDTH = 8 ; // @IPC int 1,256

    localparam SHIFT_REG_TYPE = "fixed_latency" ; // @IPC enum fixed_latency,dynamic_latency

    localparam SHIFT_REG_TYPE_BOOL = 0 ; // @IPC bool

    localparam RST_TYPE = "ASYNC" ; // @IPC enum ASYNC,SYNC



    localparam  DEPTH      = (SHIFT_REG_TYPE=="fixed_latency")   ? FIXED_DEPTH :
                             (SHIFT_REG_TYPE=="dynamic_latency") ? VARIABLE_MAX_DEPTH : 0;


    localparam  ADDR_WIDTH = (DEPTH<=16)   ? 4 :
                             (DEPTH<=32)   ? 5 :
                             (DEPTH<=64)   ? 6 :
                             (DEPTH<=128)  ? 7 :
                             (DEPTH<=256)  ? 8 :
                             (DEPTH<=512)  ? 9 : 10     ;
                                
    localparam USED_DEPTH = (SHIFT_REG_TYPE=="fixed_latency"  ) ? DEPTH : DEPTH + 1;                                


// variable declaration
    reg                       clk_tb     ;
    reg                       tb_rst     ;
    reg   [ADDR_WIDTH-1:0]    tb_addr    ;
    reg   [ADDR_WIDTH-1:0]    addr       ;
    reg   [DATA_WIDTH-1:0]    tb_wrdata  ;
    wire  [DATA_WIDTH-1:0]    tb_rddata  ;
    reg                       check_err  ;
    reg   [2:0]               results_cnt;
    wire  [DATA_WIDTH-1:0]    tb_tmp     ;
    reg   [10:0]              cnt        ;
    reg                       cmp_en     ;

assign  tb_tmp = tb_rddata + USED_DEPTH;
//************************************************************ CGU ****************************************************************************
//generate clk_tb
initial
begin

    clk_tb = 0;
    forever #(T_CLK_PERIOD/2)  clk_tb = ~clk_tb;
end


//********************************************************* DGU ********************************************************************************

initial begin

   tb_addr     = 0;
   tb_wrdata   = 0;
   cnt         = 0;
   tb_rst      = 1;
   
   #T_RST_TIME    ;
   tb_rst      = 0;
   #10            ;
   $display("writing shiftregister");
   write_shiftregister;
   #10;
   $display("shiftregister Simulation done");
   if (|results_cnt)
       $display("Simulation Failed due to Error Found.") ;
   else
       $display("Simulation Success.") ;
   $finish ;
end


//***************************************************************** DUT  INST **************************************************************************************

always@(posedge clk_tb or posedge tb_rst) begin
	if(tb_rst)
	    check_err = 0;
	else begin
		cnt = cnt + 1;
		if(cnt > USED_DEPTH + 1 && tb_wrdata != tb_tmp && cmp_en) begin
			check_err = 1;
		end
		else
		    check_err = 0;
	end
end

always @(posedge clk_tb or posedge tb_rst)
begin
    if (tb_rst)
        results_cnt <= 3'b000 ;
    else if (&results_cnt)
        results_cnt <= 3'b100 ;
    else if (check_err)
        results_cnt <= results_cnt + 3'd1 ;
end

integer  result_fid;
initial begin
     result_fid = $fopen ("sim_results.log","a");
     $fmonitor(result_fid,"err_chk=%b",check_err);
end

GTP_GRS GRS_INST(
.GRS_N(1'b1)
);
udp_shift_register  U_udp_shift_register  (
    
    .din         (tb_wrdata ),          //input  wire [`T_A_DATA_WIDTH-1 : 0]
    .dout        (tb_rddata ),          //output wire [`T_A_DATA_WIDTH-1 : 0]
    .rst         (tb_rst    ),          //input  wire
    .clk         (clk_tb    )
);

task write_shiftregister;

   integer i;
   begin
     tb_wrdata   = 0;
     tb_addr     = 0;
     cmp_en      = 0;

     while ( tb_addr < 2**ADDR_WIDTH - 1)

     begin
        @(posedge clk_tb);
        tb_addr   = tb_addr + 1'b1;
        tb_wrdata = tb_wrdata + 1'b1;
        cmp_en    = 1'b1;
     end
     cmp_en    = 0;
   end
endtask

endmodule

