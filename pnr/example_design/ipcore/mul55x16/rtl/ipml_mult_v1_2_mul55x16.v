
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
// Filename:ipml_mult.v
//////////////////////////////////////////////////////////////////////////////
module ipml_mult_v1_2_mul55x16
#(
    parameter   ASIZE           = 54,
    parameter   BSIZE           = 27,
    parameter   PSIZE           = ASIZE + BSIZE,

    parameter   OPTIMAL_TIMING  = 0,
    parameter   INREG_EN        = 0,
    parameter   PIPEREG_EN_1    = 0,
    parameter   PIPEREG_EN_2    = 0,
    parameter   PIPEREG_EN_3    = 0,
    parameter   OUTREG_EN       = 0,

    parameter   GRS_EN          = "FALSE",      //"TRUE","FALSE",enable global reset
    parameter   A_SIGNED        = 0,
    parameter   B_SIGNED        = 0,

    parameter   ASYNC_RST       = 1             // RST is sync/async

)(
    input                   ce,
    input                   rst,
    input                   clk,
    input       [ASIZE-1:0] a,
    input       [BSIZE-1:0] b,
    output wire [PSIZE-1:0] p
);


localparam OPTIMAL_TIMING_BOOL = 0 ; //@IPC bool

localparam MAX_DATA_SIZE = (ASIZE >= BSIZE)? ASIZE : BSIZE;

localparam MIN_DATA_SIZE = (ASIZE < BSIZE) ? ASIZE : BSIZE;

localparam USE_SIMD      = (MAX_DATA_SIZE > 9 )? 0 : 1; // single addsub18_mult18_add48 / dual addsub9_mult9_add24

localparam USE_POSTADD   = 1'b1;

//****************************************data_size error check**********************************************************
localparam N = (MIN_DATA_SIZE < 2 )  ? 0 :
	           (MAX_DATA_SIZE <= 18) ? 1 :
               (MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <= 18) ? 2 :    //36x18
               (MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE <= 27) ? 4 :    //27x27
               (MAX_DATA_SIZE <= 36) ? 4 :                           //36x36
               (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 18) ? 3 :    //54x18
               (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 27) ? 6 :    //54x27
               (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 36) ? 6 :    //54x36
               (MAX_DATA_SIZE <= 54) ? 9 :                           //54x54
               (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 18) ? 4 :    //72x18
               (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 36) ? 8 :    //72x36
               (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 54) ? 12 :   //72x54
               (MAX_DATA_SIZE <= 72) ? 16 : 0 ;                      //72x72

//***********************************************GTP SIGNED*******************************************************
localparam [0:0]M_A_SIGNED = (ASIZE >= BSIZE) ? A_SIGNED : B_SIGNED ;
localparam [0:0]M_B_SIGNED = (ASIZE <  BSIZE) ? A_SIGNED : B_SIGNED ;

localparam [15:0] M_A_IN_SIGNED = (MIN_DATA_SIZE < 2) ? 0 :
                  (MAX_DATA_SIZE <= 18) ? M_A_SIGNED :
                  (MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <= 18) ? {M_A_SIGNED,1'b0} :                          //36x18
                  (MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE <= 27) ? {{2{M_A_SIGNED}},2'b0} :                     //27x27
                  (MAX_DATA_SIZE <= 36) ? {{2{M_A_SIGNED}},2'b0} :                                            //36x36
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 18) ? {M_A_SIGNED,2'b0} :                          //54x18
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 27) ? {{2{M_A_SIGNED}},4'b0} :                     //54x27
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 36) ? {{2{M_A_SIGNED}},4'b0} :                     //54x36
                  (MAX_DATA_SIZE <= 54) ? {{2{M_A_SIGNED}},1'b0,M_A_SIGNED,5'b0} :                            //54x54
                  (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 18) ? {M_A_SIGNED,3'b0} :                          //72x18
                  (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 36) ? {{2{M_A_SIGNED}},6'b0} :                     //72x36
                  (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 54) ? {{2{M_A_SIGNED}},3'b0,M_A_SIGNED,6'b0} :     //72x54
                  (MAX_DATA_SIZE <= 72) ? {{2{M_A_SIGNED}},2'b0,M_A_SIGNED,2'b0,M_A_SIGNED,8'b0} : 0 ;        //72x72

localparam [15:0] M_B_IN_SIGNED = (MIN_DATA_SIZE < 2) ? 0 :
                  (MAX_DATA_SIZE <= 18) ? M_B_SIGNED :
                  (MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <= 18) ? {2{M_B_SIGNED}} :                            //36x18
                  (MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE <= 27) ? {2{M_B_SIGNED,1'b0}} :                       //27x27
                  (MAX_DATA_SIZE <= 36) ? {2{M_B_SIGNED,1'b0}} :                                              //36x36
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 18) ? {3{M_B_SIGNED}} :                            //54x18
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 27) ? {3{M_B_SIGNED,1'b0}} :                       //54x27
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 36) ? {3{M_B_SIGNED,1'b0}} :                       //54x36
                  (MAX_DATA_SIZE <= 54) ? {M_B_SIGNED,1'b0,M_B_SIGNED,2'b0,M_B_SIGNED,3'b0} :                 //54x54
                  (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 18) ? {4{M_B_SIGNED}} :                            //72x18
                  (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 36) ? {4{M_B_SIGNED,1'b0}} :                       //72x36
                  (MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <= 54) ? {{4{M_B_SIGNED,1'b0}},4'b0} :                //72x54
                  (MAX_DATA_SIZE <= 72) ? {{2{M_B_SIGNED,1'b0}},1'b0,M_B_SIGNED,2'b0,M_B_SIGNED,7'b0} : 0 ;   //72x72

//*********************************************************a_sign_ext**************************************************
localparam m_a_sign_ext_bit   = (MAX_DATA_SIZE <=9) ? 9 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 9  && MAX_DATA_SIZE < 18)? 18 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)? 36 - MAX_DATA_SIZE :  //27ext to 36
                                (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE < 36)? 36 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE < 54)? 54 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE < 72)? 72 - MAX_DATA_SIZE : 0;

localparam m_a_sign_ext_bit_s = (m_a_sign_ext_bit>= 1) ? m_a_sign_ext_bit-1 : 0;

localparam m_a_data_lsb       = (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 36 )? 18 :
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 )? 36 :
                                (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <= 72 )? 54 : 0;

//*********************************************************b_sign_ext**************************************************
localparam m_b_sign_ext_bit   = (MAX_DATA_SIZE <=9) ? 9 - MIN_DATA_SIZE :                                                //9x9
                                (MAX_DATA_SIZE > 9  && MAX_DATA_SIZE <= 18)? 18 - MIN_DATA_SIZE :                        //18x18
                                (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <=18)? 18 - MIN_DATA_SIZE :  //36x18
                                (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE > 18)? 36 - MIN_DATA_SIZE :  //27x27 27ext to 36
                                (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE > 18)? 36 - MIN_DATA_SIZE :  //36x36
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=18)? 18 - MIN_DATA_SIZE :  //54x18
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=27)? 36 - MIN_DATA_SIZE :  //54x27
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=36)? 36 - MIN_DATA_SIZE :  //54x36
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 36)? 54 - MIN_DATA_SIZE :  //54x54
                                (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <=18)? 18 - MIN_DATA_SIZE :  //72x18
                                (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <=36)? 36 - MIN_DATA_SIZE :  //72x36
                                (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <=54)? 54 - MIN_DATA_SIZE :  //72x54
                                (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <= 72)? 72 - MIN_DATA_SIZE : 0;                     //72x72


localparam m_b_data_lsb       = (MIN_DATA_SIZE > 18 && MIN_DATA_SIZE <= 36 )? 18 :
                                (MIN_DATA_SIZE > 36 && MIN_DATA_SIZE <= 54 )? 36 :
                                (MIN_DATA_SIZE > 54 && MIN_DATA_SIZE <= 72 )? 54 : 0;
localparam m_b_sign_ext_bit_s = (m_b_sign_ext_bit>=1) ? m_b_sign_ext_bit-1 : 0;

//****************************************************************GTP_APM_E1 number****************************************
localparam GTP_APM_E1_NUM = (MAX_DATA_SIZE <= 9) ? 1 :                                                      //9x9
                            (MAX_DATA_SIZE <= 18)? 1 :                                                      //18x18
                            (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)? 2 :           //36x18
                            (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)? 4 :                                 //27x27
                            (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)? 4 :           //36x36
                            (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)? 3 :           //54x18
                            (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)? 6 :           //54x27
                            (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)? 6 :           //54x36
                            (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE > 36)? 9 :           //54x54
                            (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=18)? 4 :           //72x18
                            (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=36)? 8 :           //72x36
                            (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=54)? 12 :          //72x54
                            (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE > 54)? 16 : 0 ;      //72x72

//****************************************************************GTP_APM_E1 cascade****************************************
localparam [15:0] X_SEL = (MAX_DATA_SIZE <= 9) ? 16'b0 :                                                                        //9x9
                          (MAX_DATA_SIZE <= 18)? 16'b0 :                                                                        //18x18
                          (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <= 18)? 16'b0 :                            //36x18
                          (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)? 16'b0000_0000_0000_1010 :                                 //27x27
                          (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)? 16'b0000_0000_0000_1010 :           //36x36
                          (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)? 16'b0 :                             //54x18
                          (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)? 16'b0000_0000_0010_1010 :           //54x27
                          (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)? 16'b0000_0000_0010_1010 :           //54x36
                          (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE > 36)? 16'b0000_0001_0000_0010 :           //54x54
                          (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=18)? 16'b0 :                             //72x18
                          (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=36)? 16'b0000_0000_1010_1010 :           //72x36
                          (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=54)? 16'b0000_1010_0000_1010 :           //72x54
                          (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE > 54)? 16'b1010_0100_0100_1010 : 16'b0 ;   //72x72

localparam [15:0] CXO_REG_1 = (OPTIMAL_TIMING == 0 ) ? 16'b0 :
                              (MAX_DATA_SIZE <= 9) ? 16'b0 :                                                                        //9x9
                              (MAX_DATA_SIZE <= 18)? 16'b0 :                                                                        //18x18
                              (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)? 16'b0 :                             //36x18
                              (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)? 16'b0 :                                                   //27x27
                              (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)? 16'b0 :                             //36x36
                              (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)? 16'b0 :                             //54x18
                              (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)? 16'b0 :                             //54x27
                              (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)? 16'b0 :                             //54x36
                              (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE > 36)? 16'b0000_0000_1000_0000 :           //54x54
                              (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=18)? 16'b0 :                             //72x18
                              (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=36)? 16'b0 :                             //72x36
                              (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=54)? 16'b0 :                             //72x54
                              (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE > 54)? 16'b0000_0010_0010_0000 : 16'b0 ;   //72x72

localparam [15:0] CPO_REG   = (OPTIMAL_TIMING == 0 ) ? 16'b0 :
                              (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)? 16'b0 :  16'b1010_1010_1010_1010;   //54x18


//**************************************************************************************************************************
initial
begin
    if (N == 0)
        $display("apm_mult parameter setting error!!! DATA_SIZE must between 2-72");
end

//**********************************************************reg & wire******************************************************
wire            rst_sync ;
wire            rst_async;

wire [71:0]     m_a;
wire [71:0]     m_b;
wire [47:0]     m_p[15:0];
wire [47:0]     cpo[15:0];
wire [17:0]     cxo[15:0];

reg  [17:0]     m_a_0;
reg  [17:0]     m_a_1;
reg  [17:0]     m_a_2;
reg  [17:0]     m_a_3;
reg  [17:0]     m_b_0;
reg  [17:0]     m_b_1;
reg  [17:0]     m_b_2;
reg  [17:0]     m_b_3;
reg  [17:0]     m_a_sign_ext;
reg  [17:0]     m_b_sign_ext;

reg  [15:0]     modez_0;

reg  [17:0]     m_a_div   [15:0];
reg  [17:0]     m_a_div_ff[15:0];
reg  [17:0]     m_b_div   [15:0];
reg  [17:0]     m_b_div_ff[15:0];
wire [17:0]     m_a_in    [15:0];
wire [17:0]     m_b_in    [15:0];

reg  [143:0]    m_p_o;
reg  [143:0]    m_p_o_ff;


//rst
assign rst_sync  = (ASYNC_RST == 0)  ? rst : 1'b0;
assign rst_async = (ASYNC_RST == 1)  ? rst : 1'b0;

assign m_a = (ASIZE >= BSIZE) ? a : b;
assign m_b = (ASIZE < BSIZE)  ? a : b;

//*******************************************************partition input data***********************************************
//data a
always@(*)
begin
	if (MAX_DATA_SIZE < 9)
        m_a_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a[MAX_DATA_SIZE-1]}},{MAX_DATA_SIZE{1'b0}}};
    else if (MAX_DATA_SIZE < 18)
        m_a_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a[MAX_DATA_SIZE-1]}},{MAX_DATA_SIZE{1'b0}}};
	else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)
        m_a_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a[MAX_DATA_SIZE-1]}},{{MAX_DATA_SIZE-m_a_data_lsb}{1'b0}}};
	else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE < 36)
        m_a_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a[MAX_DATA_SIZE-1]}},{{MAX_DATA_SIZE-m_a_data_lsb}{1'b0}}};
	else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE < 54)
        m_a_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a[MAX_DATA_SIZE-1]}},{(MAX_DATA_SIZE-m_a_data_lsb){1'b0}}};
	else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE < 72)
        m_a_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a[MAX_DATA_SIZE-1]}},{(MAX_DATA_SIZE-m_a_data_lsb){1'b0}}};
    else
        m_a_sign_ext = 0;
end

always@(*)
begin
    if (MAX_DATA_SIZE <= 9)
    begin
        m_a_0[8:0] = {m_a_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s:MAX_DATA_SIZE],m_a[MAX_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 9 && MAX_DATA_SIZE < 18)
    begin
		m_a_0 = {m_a_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s:MAX_DATA_SIZE],m_a[MAX_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE == 18)
    begin
		m_a_0 = m_a[MAX_DATA_SIZE-1:0];
    end
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)
    begin
        m_a_0 = m_a[17:0];
        m_a_1 = {m_a_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a[MAX_DATA_SIZE-1:m_a_data_lsb]};//ext to 36
	end
	else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE < 36)
    begin
        m_a_0 = m_a[17:0];
		m_a_1 = {m_a_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a[MAX_DATA_SIZE-1:m_a_data_lsb]};
	end
	else if (MAX_DATA_SIZE == 36)
    begin
        m_a_0 = m_a[17:0];
		m_a_1 = m_a[MAX_DATA_SIZE-1:m_a_data_lsb];
	end
	else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE < 54 )
    begin
		m_a_0 = m_a[17:0];
        m_a_1 = m_a[35:18];
		m_a_2 = {m_a_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a[MAX_DATA_SIZE-1:m_a_data_lsb]};
	end
	else if (MAX_DATA_SIZE == 54)
    begin
		m_a_0 = m_a[17:0];
        m_a_1 = m_a[35:18];
		m_a_2 = m_a[MAX_DATA_SIZE-1:m_a_data_lsb];
	end
	else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE < 72)
    begin
		m_a_0 = m_a[17:0];
        m_a_1 = m_a[35:18];
        m_a_2 = m_a[53:36];
		m_a_3 = {m_a_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a[MAX_DATA_SIZE-1:m_a_data_lsb]};
	end
	else if (MAX_DATA_SIZE == 72)
    begin
		m_a_0 = m_a[17:0];
        m_a_1 = m_a[35:18];
        m_a_2 = m_a[53:36];
		m_a_3 = m_a[MAX_DATA_SIZE-1:m_a_data_lsb];
	end
end

//data b
always@(*) begin
    if (MAX_DATA_SIZE <=9)                                                                                           //9x9
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
    else if (MAX_DATA_SIZE <=18 && MIN_DATA_SIZE <= 18)                                                              //18x18
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)                                         //36x18
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27 && MIN_DATA_SIZE > 18)                                         //27x27
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)                                         //36x36
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)                                         //54x18
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)                                         //54x27
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)                                         //54x36
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE >36)                                          //54x54
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=18)                                         //72x18
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=36)                                         //72x36
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=54)                                         //72x54
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE >54)                                          //72x72
        m_b_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    else
        m_b_sign_ext = 0;
end

always@(*) begin
	if (MAX_DATA_SIZE <= 9)     //9x9
    begin
		m_b_0[8:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b[MIN_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 9 && MAX_DATA_SIZE <= 18 && MIN_DATA_SIZE < 18)    //18x18
    begin
		m_b_0[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b[MIN_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 9 && MAX_DATA_SIZE <= 18 && MIN_DATA_SIZE == 18)   //18x18
    begin
		m_b_0[17:0] = m_b[MIN_DATA_SIZE-1:0];
    end
	else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE < 18)    //72x18or36x18or54x18
    begin
		m_b_0[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b[MIN_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE ==18)    //72x18or36x18or54x18
    begin
		m_b_0[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:0]};
    end
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE > 18)   //27x27
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <= 36&& MIN_DATA_SIZE > 18 && MIN_DATA_SIZE < 36  )    //36x36
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <= 36&&  MIN_DATA_SIZE == 36  )    //36x36
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE > 18 && MIN_DATA_SIZE <=27)  //54x27
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE > 18 && MIN_DATA_SIZE < 36)  //54x36
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE ==36)    //54x36
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 36 && MIN_DATA_SIZE < 54 )    //54x54
    begin
		m_b_0[17:0] = m_b[17:0];
        m_b_1[17:0] = m_b[35:18];
		m_b_2[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE >45 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE ==54 )    //54x54
    begin
		m_b_0[17:0] = m_b[17:0];
        m_b_1[17:0] = m_b[35:18];
		m_b_2[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE < 36)    //72x36
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE ==36)    //72x36
    begin
        m_b_0[17:0] = m_b[17:0];
		m_b_1[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE < 54)    //72x54
    begin
        m_b_0[17:0] = m_b[17:0];
        m_b_1[17:0] = m_b[35:18];
		m_b_2[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE ==54)    //72x54
    begin
        m_b_0[17:0] = m_b[17:0];
        m_b_1[17:0] = m_b[35:18];
		m_b_2[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE >36 &&MIN_DATA_SIZE <72 )    //72x72
    begin
        m_b_0[17:0] = m_b[17:0];
        m_b_1[17:0] = m_b[35:18];
        m_b_2[17:0] = m_b[53:36];
		m_b_3[17:0] = {m_b_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE ==72 )   //72x72
    begin
		m_b_0[17:0] = m_b[17:0];
        m_b_1[17:0] = m_b[35:18];
        m_b_2[17:0] = m_b[53:36];
		m_b_3[17:0] = {{M_B_SIGNED&&m_b[MIN_DATA_SIZE-1]},m_b[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
end

//*******************************************************input data***********************************************************
always@(*)
begin
    if (MAX_DATA_SIZE <=9) //9x9
    begin
        m_a_div[0]  = m_a_0;
        m_b_div[0]  = m_b_0;
        modez_0[0] = 1'b0;
    end
    else if (MAX_DATA_SIZE>9 && MAX_DATA_SIZE <=18) //18x18
    begin
        m_a_div[0]  = m_a_0;
        m_b_div[0]  = m_b_0;
        modez_0[0] = 1'b0;
    end
    else if (MAX_DATA_SIZE >18 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <=18) //36x18
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_1;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_0;
        modez_0[1:0] = 2'b10;
    end
    else if (MAX_DATA_SIZE >18 && MAX_DATA_SIZE <=27 && MIN_DATA_SIZE >18)  //27x27
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_0;
        m_a_div[2] = m_a_1;
        m_a_div[3] = m_a_1;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_1;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_1;
        modez_0[3:0] = 4'b1010;
    end
    else if (MAX_DATA_SIZE >27 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE >=18) //36x36
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_0;
        m_a_div[2] = m_a_1;
        m_a_div[3] = m_a_1;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_1;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_1;
        modez_0[3:0] = 4'b1010;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=18) //54x18
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_1;
        m_a_div[2] = m_a_2;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_0;
        m_b_div[2] = m_b_0;
        modez_0[2:0] = 3'b110;
    end
    else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <= 72 && MIN_DATA_SIZE <=18) //72x18
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_1;
        m_a_div[2] = m_a_2;
        m_a_div[3] = m_a_3;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_0;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_0;
        modez_0[3:0] = 4'b1110;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 18 && MIN_DATA_SIZE <=27) //54x27
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_0;
        m_a_div[2] = m_a_1;
        m_a_div[3] = m_a_1;
        m_a_div[4] = m_a_2;
        m_a_div[5] = m_a_2;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_1;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_1;
        m_b_div[4] = m_b_0;
        m_b_div[5] = m_b_1;
        modez_0[5:0] = 6'b10_1010;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 27 && MIN_DATA_SIZE <=36) //54x36
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_0;
        m_a_div[2] = m_a_1;
        m_a_div[3] = m_a_1;
        m_a_div[4] = m_a_2;
        m_a_div[5] = m_a_2;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_1;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_1;
        m_b_div[4] = m_b_0;
        m_b_div[5] = m_b_1;
        modez_0[5:0] = 6'b10_1010;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 36) //54x54
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_0;
        m_a_div[2] = m_a_1;
        m_a_div[3] = m_a_0;
        m_a_div[4] = m_a_1;
        m_a_div[5] = m_a_2;
        m_a_div[6] = m_a_1;
        m_a_div[7] = m_a_2;
        m_a_div[8] = m_a_2;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_1;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_2;
        m_b_div[4] = m_b_1;
        m_b_div[5] = m_b_0;
        m_b_div[6] = m_b_2;
        m_b_div[7] = m_b_1;
        m_b_div[8] = m_b_2;
        modez_0[8:0] = 9'b1_0100_1010;
    end
    else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=36) //72x36
    begin
        m_a_div[0] = m_a_0;
        m_a_div[1] = m_a_0;
        m_a_div[2] = m_a_1;
        m_a_div[3] = m_a_1;
        m_a_div[4] = m_a_2;
        m_a_div[5] = m_a_2;
        m_a_div[6] = m_a_3;
        m_a_div[7] = m_a_3;
        m_b_div[0] = m_b_0;
        m_b_div[1] = m_b_1;
        m_b_div[2] = m_b_0;
        m_b_div[3] = m_b_1;
        m_b_div[4] = m_b_0;
        m_b_div[5] = m_b_1;
        m_b_div[6] = m_b_0;
        m_b_div[7] = m_b_1;
        modez_0[7:0] = 8'b1010_1010;
    end
    else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=54) //72x54
    begin
        m_a_div[0]  = m_a_0;
        m_a_div[1]  = m_a_0;
        m_a_div[2]  = m_a_1;
        m_a_div[3]  = m_a_1;
        m_a_div[4]  = m_a_2;
        m_a_div[5]  = m_a_0;
        m_a_div[6]  = m_a_3;
        m_a_div[7]  = m_a_1;
        m_a_div[8]  = m_a_2;
        m_a_div[9]  = m_a_2;
        m_a_div[10] = m_a_3;
        m_a_div[11] = m_a_3;
        m_b_div[0]  = m_b_0;
        m_b_div[1]  = m_b_1;
        m_b_div[2]  = m_b_0;
        m_b_div[3]  = m_b_1;
        m_b_div[4]  = m_b_0;
        m_b_div[5]  = m_b_2;
        m_b_div[6]  = m_b_0;
        m_b_div[7]  = m_b_2;
        m_b_div[8]  = m_b_1;
        m_b_div[9]  = m_b_2;
        m_b_div[10] = m_b_1;
        m_b_div[11] = m_b_2;
        modez_0[11:0] = 12'b1010_0100_1010;
    end
    else if (MAX_DATA_SIZE >54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE >54) //72x72
    begin
        m_a_div[0]  = m_a_0;
        m_a_div[1]  = m_a_0;
        m_a_div[2]  = m_a_1;
        m_a_div[3]  = m_a_1;
        m_a_div[4]  = m_a_0;
        m_a_div[5]  = m_a_2;
        m_a_div[6]  = m_a_2;
        m_a_div[7]  = m_a_0;
        m_a_div[8]  = m_a_3;
        m_a_div[9]  = m_a_1;
        m_a_div[10] = m_a_1;
        m_a_div[11] = m_a_3;
        m_a_div[12] = m_a_2;
        m_a_div[13] = m_a_2;
        m_a_div[14] = m_a_3;
        m_a_div[15] = m_a_3;
        m_b_div[0]  = m_b_0;
        m_b_div[1]  = m_b_1;
        m_b_div[2]  = m_b_0;
        m_b_div[3]  = m_b_1;
        m_b_div[4]  = m_b_2;
        m_b_div[5]  = m_b_0;
        m_b_div[6]  = m_b_1;
        m_b_div[7]  = m_b_3;
        m_b_div[8]  = m_b_0;
        m_b_div[9]  = m_b_2;
        m_b_div[10] = m_b_3;
        m_b_div[11] = m_b_1;
        m_b_div[12] = m_b_2;
        m_b_div[13] = m_b_3;
        m_b_div[14] = m_b_2;
        m_b_div[15] = m_b_3;
        modez_0    = 16'b1010_0100_0100_1010;
    end
end

genvar m_i;
generate
    for (m_i=0; m_i < GTP_APM_E1_NUM; m_i=m_i+1)
    begin
        always@(posedge clk or posedge rst_async)
        begin
            if (rst_async)
            begin
                m_a_div_ff[m_i]  <= 18'b0;
                m_b_div_ff[m_i]  <= 18'b0;
            end
            else if (rst_sync)
            begin
                m_a_div_ff[m_i]  <= 18'b0;
                m_b_div_ff[m_i]  <= 18'b0;
            end
            else
            begin
                m_a_div_ff[m_i]  <= m_a_div[m_i];
                m_b_div_ff[m_i]  <= m_b_div[m_i];
            end
        end
    end
endgenerate

genvar data_in_i;
generate
    for (data_in_i=0; data_in_i < GTP_APM_E1_NUM; data_in_i=data_in_i+1)
    begin
        assign m_a_in[data_in_i] = (INREG_EN == 1) ? m_a_div_ff[data_in_i] : m_a_div[data_in_i];
        assign m_b_in[data_in_i] = (INREG_EN == 1) ? m_b_div_ff[data_in_i] : m_b_div[data_in_i];
    end
endgenerate

//************************************************************GTP*********************************************************
genvar i;
generate
    for (i=1; i< GTP_APM_E1_NUM; i=i+1)
    begin
        GTP_APM_E1 #(
        .GRS_EN        ( GRS_EN              ),
        .X_SIGNED      ( M_A_IN_SIGNED[i]    ),
        .Y_SIGNED      ( M_B_IN_SIGNED[i]    ),
        .USE_POSTADD   ( USE_POSTADD         ),
        .X_REG         ( PIPEREG_EN_1        ),
        .CXO_REG       ( {1'b0,CXO_REG_1[i]} ),
        .Y_REG         ( PIPEREG_EN_1        ),
        .Z_REG         ( PIPEREG_EN_1        ),
        .MULT_REG      ( PIPEREG_EN_2        ),
        .P_REG         ( PIPEREG_EN_3        ),
        .X_SEL         ( X_SEL[i]            ),
        .ASYNC_RST     ( ASYNC_RST           ),
        .Z_INIT        ( 48'b0               ),
        .CPO_REG       ( CPO_REG[i]          ),
        .USE_SIMD      ( USE_SIMD            )
	     )
        mult_i(
        .P      ( m_p[i]   ),       //Postadder resout
        .CPO    ( cpo[i]   ),      //P cascade out
        .COUT   (          ),      //Postadder carry out
        .CXO    ( cxo[i]   ),      //X cascade out
        .CXBO   (          ),      //X backward cascade out
        .X      ( m_a_in[i]),
        .CXI    ( cxo[i-1] ),    //X cascade in
        .CXBI   (          ),    //X backward cascade in
        .Y      ( m_b_in[i]),
        .Z      ( 48'b1    ),
        .CPI    ( cpo[i-1] ),     //P cascade in
        .CIN    (          ),     //Postadder carry in
        .MODEX  ( 1'b0     ),     // preadder add/sub(), 0/1
        .MODEY  ( 3'b0     ),
        //ODEY encoding: 0/1
        //[0]     produce all-0 . to post adder / enable P register feedback. MODEY[1] needs to be 1 for MODEY[0] to take effect.
        //[1]     enable/disable mult . for post adder
        //[2]     +/- (mult-mux . polarity)
        .MODEZ  ( {3'b011,modez_0[i]} ),
        //[ODEZ encoding: 0/1
        //[0]     CPI / (CPI >>> 18) (select shift or non-shift CPI)
        //[2:1]   Z_INIT/P/Z/CPI (zmux . select)
        //[3]     +/- (zmux . polarity)
        .CLK        (clk),
        .RSTX       (rst),
        .RSTY       (rst),
        .RSTZ       (rst),
        .RSTM       (rst),
        .RSTP       (rst),
        .RSTPRE     (rst),
        .RSTMODEX   (rst),
        .RSTMODEY   (rst),
        .RSTMODEZ   (rst),
        .CEX        (ce),
        .CEY        (ce),
        .CEZ        (ce),
        .CEM        (ce),
        .CEP        (ce),
        .CEPRE      (ce),
        .CEMODEX    (ce),
        .CEMODEY    (ce),
        .CEMODEZ    (ce)
        );
    end
endgenerate

     GTP_APM_E1 #(
        .GRS_EN        ( GRS_EN              ),
        .X_SIGNED      ( M_A_IN_SIGNED[0]    ),
        .Y_SIGNED      ( M_B_IN_SIGNED[0]    ),
        .USE_POSTADD   ( USE_POSTADD         ),
        .X_REG         ( PIPEREG_EN_1        ),
        .CXO_REG       ( {1'b0,CXO_REG_1[0]} ),
        .Y_REG         ( PIPEREG_EN_1        ),
        .Z_REG         ( PIPEREG_EN_1        ),
        .MULT_REG      ( PIPEREG_EN_2        ),
        .P_REG         ( PIPEREG_EN_3        ),
        .X_SEL         ( X_SEL[0]            ),
        .ASYNC_RST     ( ASYNC_RST           ),
        .Z_INIT        ( 48'b0               ),
        .CPO_REG       ( CPO_REG[0]          ),
        .USE_SIMD      ( USE_SIMD             )
	     )
        mult_0(
        .P      ( m_p[0] ),     //Postadder resout
        .CPO    ( cpo[0] ),     //P cascade out
        .COUT   (        ),     //Postadder carry out
        .CXO    ( cxo[0] ),     //X cascade out
        .CXBO   (        ),     //X backward cascade out
        .X      ( m_a_in[0]),
        .CXI    (        ),     //X cascade in
        .CXBI   (        ),     //X backward cascade in
        .Y      ( m_b_in[0]),
        .Z      ( 48'b1  ),
        .CPI    (        ),     //P cascade in
        .CIN    (        ),     //Postadder carry in
        .MODEX  ( 1'b0   ),     // preadder add/sub(), 0/1
        .MODEY  ( 3'b0   ),
        .MODEZ  ( {3'b0,modez_0[0]}),
        //[ODEZ encoding: 0/1
        //[0]     CPI / (CPI >>> 18) (select shift or non-shift CPI)
        //[2:1]   Z_INIT/P/Z/CPI (zmux . select)
        //[3]     +/- (zmux . polarity)
        .CLK        (clk),
        .RSTX       (rst),
        .RSTY       (rst),
        .RSTZ       (rst),
        .RSTM       (rst),
        .RSTP       (rst),
        .RSTPRE     (rst),
        .RSTMODEX   (rst),
        .RSTMODEY   (rst),
        .RSTMODEZ   (rst),
        .CEX        (ce),
        .CEY        (ce),
        .CEZ        (ce),
        .CEM        (ce),
        .CEP        (ce),
        .CEPRE      (ce),
        .CEMODEX    (ce),
        .CEMODEY    (ce),
        .CEMODEZ    (ce)
        );

//*****************************************************************output***************************************************
 
always@(*) begin
    if (MAX_DATA_SIZE <=9)  //9x9
        m_p_o[17:0] = m_p[0][17:0];
    else if (MAX_DATA_SIZE <=18 && MIN_DATA_SIZE <= 18)  //18x18
        m_p_o[35:0] = m_p[0][35:0];
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)    //36x18
        m_p_o[53:0] = {m_p[1][35:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27 && MIN_DATA_SIZE > 18)    //27x27
        m_p_o[71:0] = {m_p[3][35:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)    //36x36
        m_p_o[71:0] = {m_p[3][35:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)    //54x18
        m_p_o[71:0] = {m_p[2][35:0],m_p[1][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)    //54x27
        m_p_o[89:0] = {m_p[5][35:0],m_p[4][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)    //54x36
        m_p_o[89:0] = {m_p[5][35:0],m_p[4][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE > 36)    //54x54
        m_p_o[107:0] = {m_p[8][35:0],m_p[7][17:0],m_p[5][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=18)    //72x18
        m_p_o[89:0]  = {m_p[3][35:0],m_p[2][17:0],m_p[1][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=36)    //72x36
        m_p_o[107:0] = {m_p[7][35:0],m_p[6][17:0],m_p[4][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE <=54)    //72x54
        m_p_o[125:0] = {m_p[11][35:0],m_p[10][17:0],m_p[8][17:0],m_p[5][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 54 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE > 54)    //72x72
        m_p_o[143:0] = {m_p[15][35:0],m_p[14][17:0],m_p[12][17:0],m_p[9][17:0],m_p[5][17:0],m_p[2][17:0],m_p[0][17:0]};
    else
        m_p_o[143:0] = 144'b0;
end

//**************************************************************output reg***********************************************************
 
always@(posedge clk or posedge rst_async)
begin
    if (rst_async)
        m_p_o_ff <= 144'b0;
    else if (rst_sync)
        m_p_o_ff <= 144'b0;
    else
        m_p_o_ff <= m_p_o;
end

assign p = (OUTREG_EN == 1) ? m_p_o_ff[PSIZE-1:0] : m_p_o[PSIZE-1:0];

endmodule
