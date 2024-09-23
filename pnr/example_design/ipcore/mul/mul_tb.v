
/////////////////////////////////////////////////////////////////////////////
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
// Filename:TB mul_tb.v
//////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ns
module mul_tb();

localparam  T_CLK_PERIOD       = 10     ;       //clock a half perid
localparam  T_RST_TIME         = 200    ;       //reset time
localparam  T_SIM_TIME         = 100000 ;       //simulation time


localparam ASIZE = 16 ; //@IPC int 2,72

localparam BSIZE = 16 ; //@IPC int 2,72

localparam A_SIGNED = 1 ; //@IPC enum 0,1

localparam B_SIGNED = 1 ; //@IPC enum 0,1

localparam ASYNC_RST = 1 ; //@IPC enum FALSE,TRUE

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
localparam  PSIZE        =   ASIZE + BSIZE           ;
 

// variable declaration
reg                 clk         ;
reg                 rst         ;
reg  [ASIZE-1:0]    a           ;
reg  [BSIZE-1:0]    b           ;
wire [PSIZE-1:0]    p           ;

wire [143:0]        a_ext       ;
wire [143:0]        b_ext       ;
wire [287:0]        p_ext       ;
reg  [PSIZE-1:0]    p_ext_ff1   ;
reg  [PSIZE-1:0]    p_ext_ff2   ;
reg  [PSIZE-1:0]    p_ext_ff3   ;
reg  [PSIZE-1:0]    p_ext_ff4   ;
reg  [PSIZE-1:0]    p_ext_ff5   ;
wire [PSIZE-1:0]    p_mult      ;
 

integer  pass;
integer  result_fid;

always #T_CLK_PERIOD clk = ~clk;

initial begin
    clk = 0;
	rst = 1;
    #T_RST_TIME
    rst = 0;
end

initial begin
	a = 'd0;
	b = 'd0;
	pass = 'd1;
end

GTP_GRS   GRS_INST( .GRS_N(1'b1) );

always@(posedge clk)
begin

      a <= $random;

      b <= $random;

end

initial begin
	$display("Simulation Starts ...\n");
	result_fid = $fopen ("sim_results.log","a");
	#T_SIM_TIME;
	$display("Simulation is done.\n");
	if (pass == 1)
		$display("Simulation Success!\n");
	else
		$display("Simulation Failed!\n");
	$finish;
end


assign a_ext = {{(144-ASIZE){a[ASIZE-1]&&A_SIGNED}},a[ASIZE-1:0]};

assign b_ext = {{(144-BSIZE){b[BSIZE-1]&&B_SIGNED}},b[BSIZE-1:0]};

assign p_ext = a_ext * b_ext;

always@(posedge clk or posedge rst)
begin
    if (rst)
    begin

        p_ext_ff1 <= 0;

        p_ext_ff2 <= 0;

        p_ext_ff3 <= 0;

        p_ext_ff4 <= 0;

        p_ext_ff5 <= 0;

	end
	else
    begin

        p_ext_ff1 <= p_ext[PSIZE-1:0];

        p_ext_ff2 <= p_ext_ff1;

        p_ext_ff3 <= p_ext_ff2;

        p_ext_ff4 <= p_ext_ff3;

        p_ext_ff5 <= p_ext_ff4;

    end
end

assign p_mult = (PIPE_STATUS == 0 ) ? p_ext[PSIZE-1:0] :
                (PIPE_STATUS == 1 ) ? p_ext_ff1 :
                (PIPE_STATUS == 2 ) ? p_ext_ff2 :
                (PIPE_STATUS == 3 ) ? p_ext_ff3 :
                (PIPE_STATUS == 4 ) ? p_ext_ff4 : p_ext_ff5 ;
 
always@(posedge clk)
begin
    if ( p_mult != p)
    begin
        $display("mult error! mult data = %h, product = %h",p_mult,p);
        $fdisplay(result_fid, "err_chk=1");
        pass = 0;
    end
end



//***************************************************************** DUT  INST ********************************************************************************
mul  U_mul
    (
	.ce     (1'b1),
	.rst    (rst),
	.clk    (clk),
	.a      (a),
	.b      (b),
	.p      (p)
    );
endmodule

