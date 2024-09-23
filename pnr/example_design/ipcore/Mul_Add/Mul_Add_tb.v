

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
// Filename:TB Mul_Add_tb.v                 
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns
module Mul_Add_tb();
localparam  T_CLK_PERIOD       = 10     ;       //clock a half perid
localparam  T_RST_TIME         = 200    ;       //reset time 
localparam  T_SIM_TIME         = 100000 ;       //reset time 

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


localparam  PSIZE       = ASIZE + BSIZE +1    ; 
 

//variable declaration
reg                 clk            ;
reg                 rst            ;
reg [ASIZE-1:0]     a0             ;
reg [ASIZE-1:0]     a1             ;
reg [BSIZE-1:0]     b0             ;
reg [BSIZE-1:0]     b1             ;
reg                 addsub;                        
wire [PSIZE-1:0]    p              ;

wire ADDSUB_OPCODE;

wire [143:0]        a0_ext         ;
wire [143:0]        a1_ext         ;
wire [143:0]        b0_ext         ;
wire [143:0]        b1_ext         ;
wire [287:0]        p_ext          ;
reg  [PSIZE-1:0]    p_ext_ff1      ;
reg  [PSIZE-1:0]    p_ext_ff2      ;
reg  [PSIZE-1:0]    p_ext_ff3      ;
reg  [PSIZE-1:0]    p_ext_ff4      ;
reg  [PSIZE-1:0]    p_ext_ff5      ;
wire [PSIZE-1:0]    p_multadd      ;
 

integer  pass;

initial begin
    clk = 0;
	rst = 1;
    #T_RST_TIME 
    rst = 0;
end

GTP_GRS   GRS_INST( .GRS_N(1'b1) );

initial begin
	a1 = 1;
	a0 = 0;
	b1 = 1;
	b0 = 0;
	addsub = 1;
	pass = 1;
end

always #T_CLK_PERIOD  clk = ~clk;

always@(posedge clk) 
begin

    a0 <= {$random,$random};

    a1 <= {$random,$random};

    b0 <= {$random,$random};

    b1 <= {$random,$random};

      addsub <= $random;

end

integer  result_fid;
initial 
begin
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


assign a0_ext = {{(144-ASIZE){a0[ASIZE-1]&&A_SIGNED}},a0[ASIZE-1:0]};

assign b0_ext = {{(144-BSIZE){b0[BSIZE-1]&&B_SIGNED}},b0[BSIZE-1:0]};

assign a1_ext = {{(144-ASIZE){a1[ASIZE-1]&&A_SIGNED}},a1[ASIZE-1:0]};

assign b1_ext = {{(144-BSIZE){b1[BSIZE-1]&&B_SIGNED}},b1[BSIZE-1:0]};


assign ADDSUB_OPCODE = (DYN_ADDSUB_OP == 1)? addsub : ADDSUB_OP;

assign p_ext = (ADDSUB_OPCODE == 0) ?a0_ext * b0_ext + a1_ext * b1_ext :a0_ext * b0_ext - a1_ext * b1_ext  ;

always@(posedge clk or posedge rst) 
begin
	if(rst) 
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

assign p_multadd = (PIPE_STATUS == 0 ) ? p_ext[PSIZE-1:0] :
                   (PIPE_STATUS == 1 ) ? p_ext_ff1 :
                   (PIPE_STATUS == 2 ) ? p_ext_ff2 :            
                   (PIPE_STATUS == 3 ) ? p_ext_ff3 :
                   (PIPE_STATUS == 4 ) ? p_ext_ff4 : p_ext_ff5 ;

 
always@(posedge clk) 
begin
	if ( p_multadd != p) 
    begin
		$display("multadd error! multadd data = %h, product = %h",p_multadd,p); 
		$fdisplay(result_fid, "err_chk=1");
		pass = 0;
	end		     
end

//***************************************************************** DUT  INST ********************************************************************************
Mul_Add  U_Mul_Add
(
	.ce     ( 1'b1  ),
	.rst    ( rst   ),
	.clk    ( clk   ),
	.a0     ( a0    ),
	.a1     ( a1    ),
	.b0     ( b0    ),
	.b1     ( b1    ),
	
	.addsub ( addsub),
	
	.p      ( p     )
 );

 endmodule

