
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
// Filename:ipml_multadd.v
//////////////////////////////////////////////////////////////////////////////
    module ipml_multadd_v1_1_Mul_Add
#(  
    parameter   ASIZE           = 54,
    parameter   BSIZE           = 27,
    parameter   PSIZE           = ASIZE + BSIZE+1,
    
    parameter   OPTIMAL_TIMING  = 0,
    parameter   INREG_EN        = 0,     
    parameter   PIPEREG_EN_1    = 0,  
    parameter   PIPEREG_EN_2    = 0,
    parameter   PIPEREG_EN_3    = 0,
    parameter   OUTREG_EN       = 0,
        
    parameter   GRS_EN          = "FALSE",      //"TRUE","FALSE",enable global reset
    parameter   A_SIGNED        = 0,        
    parameter   B_SIGNED        = 0,        
        
    parameter   ASYNC_RST       = 1,            // RST is sync/async 
    
    parameter   ADDSUB_OP       = 0,   
    parameter   DYN_ADDSUB_OP   = 1    

)(
    input                   ce,
    input                   rst,
    input                   clk,
    input       [ASIZE-1:0] a0,
    input       [ASIZE-1:0] a1,
    input       [BSIZE-1:0] b0,
    input       [BSIZE-1:0] b1,
    input                   addsub,         //0:add 1:sub
    output wire [PSIZE-1:0] p
);

localparam OPTIMAL_TIMING_BOOL = 0 ; //@IPC bool

localparam MAX_DATA_SIZE = (ASIZE >= BSIZE)? ASIZE : BSIZE;
 
localparam MIN_DATA_SIZE = (ASIZE < BSIZE) ? ASIZE : BSIZE;

localparam USE_SIMD      = (MAX_DATA_SIZE > 9 )? 0 : 1;     // single addsub18_mult18_add48 / dual addsub9_mult9_add24

localparam USE_POSTADD   = 1'b1;

//****************************************data_size error check********************************************************** 
localparam N = (MIN_DATA_SIZE < 2 )  ? 0 :
	           (MAX_DATA_SIZE <= 18) ? 2 :
               (MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <= 18) ? 4  :    //36x18
               (MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE <= 27) ? 8  :    //27x27
               (MAX_DATA_SIZE <= 36) ? 8 :                            //36x36
               (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 18) ? 6  :    //54x18
               (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 27) ? 12 :    //54x27
               (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 36) ? 12 :    //54x36
               (MAX_DATA_SIZE <= 54) ? 18 : 0;                        //54x54

//***********************************************GTP SIGNED*******************************************************
localparam [0:0]M_A_SIGNED = (ASIZE >= BSIZE) ? A_SIGNED : B_SIGNED ;
localparam [0:0]M_B_SIGNED = (ASIZE <  BSIZE) ? A_SIGNED : B_SIGNED ;

localparam [8:0] M_A_IN_SIGNED = (MIN_DATA_SIZE < 2) ? 0 :
                  (MAX_DATA_SIZE <= 18) ? M_A_SIGNED :
                  (MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <= 18) ? {M_A_SIGNED,1'b0} :                          //36x18
                  (MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE <= 27) ? {{2{M_A_SIGNED}},2'b0} :                     //27x27
                  (MAX_DATA_SIZE <= 36) ? {{2{M_A_SIGNED}},2'b0} :                                            //36x36
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 18) ? {M_A_SIGNED,2'b0} :                          //54x18
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 27) ? {{2{M_A_SIGNED}},4'b0} :                     //54x27
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 36) ? {{2{M_A_SIGNED}},4'b0} :                     //54x36
                  (MAX_DATA_SIZE <= 54) ? {{2{M_A_SIGNED}},1'b0,M_A_SIGNED,5'b0} : 0 ;                        //54x54

localparam [8:0] M_B_IN_SIGNED = (MIN_DATA_SIZE < 2) ? 0 :
                  (MAX_DATA_SIZE <= 18) ? M_B_SIGNED : 
                  (MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <= 18) ? {2{M_B_SIGNED}} :                            //36x18
                  (MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE <= 27) ? {2{M_B_SIGNED,1'b0}} :                       //27x27
                  (MAX_DATA_SIZE <= 36) ? {2{M_B_SIGNED,1'b0}} :                                              //36x36
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 18) ? {3{M_B_SIGNED}} :                            //54x18
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 27) ? {3{M_B_SIGNED,1'b0}} :                       //54x27
                  (MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <= 36) ? {3{M_B_SIGNED,1'b0}} :                       //54x36
                  (MAX_DATA_SIZE <= 54) ? {M_B_SIGNED,1'b0,M_B_SIGNED,2'b0,M_B_SIGNED,3'b0} : 0 ;             //54x54

//*********************************************************a_sign_ext**************************************************                 
localparam m_a_sign_ext_bit   = (MAX_DATA_SIZE <=9) ? 9 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 9  && MAX_DATA_SIZE < 18)? 18 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)? 36 - MAX_DATA_SIZE :  //27ext to 36
                                (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE < 36)? 36 - MAX_DATA_SIZE :
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE < 54)? 54 - MAX_DATA_SIZE : 0; 

localparam m_a_sign_ext_bit_s = (m_a_sign_ext_bit>= 1) ? m_a_sign_ext_bit-1 : 0;

localparam m_a_data_lsb       = (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 36 )? 18 :  
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 )? 36 : 0;

//*********************************************************b_sign_ext**************************************************      
localparam m_b_sign_ext_bit   = (MAX_DATA_SIZE <=9) ? 9 - MIN_DATA_SIZE :                                                  //9x9
                                (MAX_DATA_SIZE > 9  && MAX_DATA_SIZE <= 18)? 18 - MIN_DATA_SIZE :                          //18x18
                                (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <=18)? 18 - MIN_DATA_SIZE :    //36x18
                                (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE > 18)? 36 - MIN_DATA_SIZE :    //27x27 27ext to 36
                                (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE > 18)? 36 - MIN_DATA_SIZE :    //36x36
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=18)? 18 - MIN_DATA_SIZE :    //54x18
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=27)? 36 - MIN_DATA_SIZE :    //54x27
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=36)? 36 - MIN_DATA_SIZE :    //54x36
                                (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 36)? 54 - MIN_DATA_SIZE : 0; //54x54
 
localparam m_b_sign_ext_bit_s = (m_b_sign_ext_bit>=1) ? m_b_sign_ext_bit-1 : 0;  
               
localparam m_b_data_lsb       = (MIN_DATA_SIZE > 18 && MIN_DATA_SIZE <= 36 )? 18 :  
                                (MIN_DATA_SIZE > 36 && MIN_DATA_SIZE <= 54 )? 36 : 0;    
                             
//****************************************************************GTP_APM_E1 group number****************************************
localparam GTP_APM_E1_GROUP_NUM = (MAX_DATA_SIZE <= 9) ? 1 :                                                //9x9
                                  (MAX_DATA_SIZE <= 18)? 1 :                                                      //18x18
                                  (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)? 2 :           //36x18
                                  (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)? 4 :                                 //27x27                            
                                  (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)? 4 :           //36x36
                                  (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)? 3 :           //54x18                            
                                  (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)? 6 :           //54x27                           
                                  (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)? 6 :           //54x36                           
                                  (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE > 36)? 9 : 0 ;       //54x54                           
                            
//****************************************************************GTP_APM_E1 cascade****************************************                                                  
localparam [8:0] CPO_REG   = (OPTIMAL_TIMING == 0 ) ? 9'b0 : 9'h1_ff;   
                          
//**************************************************************************************************************************                            
initial 
begin
    if (N == 0)
        $display("apm_mult parameter setting error!!! DATA_SIZE must between 2-72");
end 
  
//**********************************************************reg & wire******************************************************
wire            rst_sync ;
wire            rst_async;

wire [53:0]     m_a0;
wire [53:0]     m_a1;
wire [53:0]     m_b0;
wire [53:0]     m_b1;

wire [47:0]     m_p[8:0];
wire [47:0]     cpo[17:0];
    
reg  [17:0]     m_a0_0;
reg  [17:0]     m_a0_1;
reg  [17:0]     m_a0_2;
reg  [17:0]     m_a1_0;
reg  [17:0]     m_a1_1;
reg  [17:0]     m_a1_2;

reg  [17:0]     m_b0_0;
reg  [17:0]     m_b0_1;
reg  [17:0]     m_b0_2;
reg  [17:0]     m_b1_0;
reg  [17:0]     m_b1_1;
reg  [17:0]     m_b1_2;

reg  [17:0]     m_a0_sign_ext;
reg  [17:0]     m_a1_sign_ext;
reg  [17:0]     m_b0_sign_ext;
reg  [17:0]     m_b1_sign_ext;

reg  [8:0]      modez_0;
    
reg  [17:0]     m_a0_div   [15:0];
reg  [17:0]     m_a1_div   [15:0];
reg  [17:0]     m_a0_div_ff[15:0];
reg  [17:0]     m_a1_div_ff[15:0];
reg  [17:0]     m_b0_div   [15:0];
reg  [17:0]     m_b1_div   [15:0];
reg  [17:0]     m_b0_div_ff[15:0];
reg  [17:0]     m_b1_div_ff[15:0];
wire [17:0]     m_a0_in    [15:0];
wire [17:0]     m_a1_in    [15:0];
wire [17:0]     m_b0_in    [15:0];
wire [17:0]     m_b1_in    [15:0];
      
reg  [108:0]    m_p_o;
reg  [108:0]    m_p_o_ff;

//addsub
reg             addsub_1d;
reg             addsub_2d;
wire            addsub_d1;
wire [8:0]      addsub_in;

//rst
assign rst_sync  = (ASYNC_RST == 0)  ? rst : 1'b0;
assign rst_async = (ASYNC_RST == 1)  ? rst : 1'b0;

assign m_a0 = (ASIZE >= BSIZE) ? a0 : b0;
assign m_a1 = (ASIZE >= BSIZE) ? a1 : b1;
assign m_b0 = (ASIZE < BSIZE)  ? a0 : b0;
assign m_b1 = (ASIZE < BSIZE)  ? a1 : b1;

//*******************************************************partition input data***********************************************
//data a
always@(*) 
begin
	if (MAX_DATA_SIZE < 9)
    begin
        m_a0_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a0[MAX_DATA_SIZE-1]}},{MAX_DATA_SIZE{1'b0}}}; 
        m_a1_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a1[MAX_DATA_SIZE-1]}},{MAX_DATA_SIZE{1'b0}}}; 
    end
    else if (MAX_DATA_SIZE < 18)
    begin
        m_a0_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a0[MAX_DATA_SIZE-1]}},{MAX_DATA_SIZE{1'b0}}}; 
        m_a1_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a1[MAX_DATA_SIZE-1]}},{MAX_DATA_SIZE{1'b0}}}; 
    end
	else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27)  
    begin
        m_a0_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a0[MAX_DATA_SIZE-1]}},{{MAX_DATA_SIZE-m_a_data_lsb}{1'b0}}}; 
        m_a1_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a1[MAX_DATA_SIZE-1]}},{{MAX_DATA_SIZE-m_a_data_lsb}{1'b0}}}; 
    end
	else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE < 36)  
    begin
        m_a0_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a0[MAX_DATA_SIZE-1]}},{{MAX_DATA_SIZE-m_a_data_lsb}{1'b0}}}; 
        m_a1_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a1[MAX_DATA_SIZE-1]}},{{MAX_DATA_SIZE-m_a_data_lsb}{1'b0}}}; 
    end
	else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE < 54) 
    begin
        m_a0_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a0[MAX_DATA_SIZE-1]}},{(MAX_DATA_SIZE-m_a_data_lsb){1'b0}}}; 
        m_a1_sign_ext = {{m_a_sign_ext_bit{M_A_SIGNED && m_a1[MAX_DATA_SIZE-1]}},{(MAX_DATA_SIZE-m_a_data_lsb){1'b0}}};
    end
    else
    begin
        m_a0_sign_ext = 0;
        m_a1_sign_ext = 0;
    end
end

always@(*) 
begin
    if (MAX_DATA_SIZE <= 9)
    begin
        m_a0_0[8:0] = {m_a0_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s:MAX_DATA_SIZE],m_a0[MAX_DATA_SIZE-1:0]};
        m_a1_0[8:0] = {m_a1_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s:MAX_DATA_SIZE],m_a1[MAX_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 9 && MAX_DATA_SIZE < 18)
    begin
		m_a0_0 = {m_a0_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s:MAX_DATA_SIZE],m_a0[MAX_DATA_SIZE-1:0]};
		m_a1_0 = {m_a1_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s:MAX_DATA_SIZE],m_a1[MAX_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE == 18)  
    begin
		m_a0_0 = m_a0[MAX_DATA_SIZE-1:0];
		m_a1_0 = m_a1[MAX_DATA_SIZE-1:0];
    end
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27) 
    begin
        m_a0_0 = m_a0[17:0];
        m_a1_0 = m_a1[17:0];
        m_a0_1 = {m_a0_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a0[MAX_DATA_SIZE-1:m_a_data_lsb]};//ext to 36
        m_a1_1 = {m_a1_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a1[MAX_DATA_SIZE-1:m_a_data_lsb]};//ext to 36
	end
	else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE < 36) 
    begin
        m_a0_0 = m_a0[17:0];
        m_a1_0 = m_a1[17:0];
		m_a0_1 = {m_a0_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a0[MAX_DATA_SIZE-1:m_a_data_lsb]};
		m_a1_1 = {m_a1_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a1[MAX_DATA_SIZE-1:m_a_data_lsb]};
	end
	else if (MAX_DATA_SIZE == 36) 
    begin
        m_a0_0 = m_a0[17:0];
        m_a1_0 = m_a1[17:0];
		m_a0_1 = m_a0[MAX_DATA_SIZE-1:m_a_data_lsb];
		m_a1_1 = m_a1[MAX_DATA_SIZE-1:m_a_data_lsb];
	end
	else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE < 54 ) 
    begin
		m_a0_0 = m_a0[17:0];
		m_a1_0 = m_a1[17:0];
        m_a0_1 = m_a0[35:18];
        m_a1_1 = m_a1[35:18];
		m_a0_2 = {m_a0_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a0[MAX_DATA_SIZE-1:m_a_data_lsb]};           
		m_a1_2 = {m_a1_sign_ext[MAX_DATA_SIZE+m_a_sign_ext_bit_s-m_a_data_lsb:MAX_DATA_SIZE-m_a_data_lsb],m_a1[MAX_DATA_SIZE-1:m_a_data_lsb]};           
	end
	else if (MAX_DATA_SIZE == 54) 
    begin
		m_a0_0 = m_a0[17:0];
		m_a1_0 = m_a1[17:0];
        m_a0_1 = m_a0[35:18];
        m_a1_1 = m_a1[35:18];
		m_a0_2 = m_a0[MAX_DATA_SIZE-1:m_a_data_lsb];
		m_a1_2 = m_a1[MAX_DATA_SIZE-1:m_a_data_lsb];
	end
end

//data b          
always@(*) 
begin
    if (MAX_DATA_SIZE <=9)                                                                                           //9x9
    begin
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}}; 
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}}; 
    end
    else if (MAX_DATA_SIZE <=18 && MIN_DATA_SIZE <= 18)                                                              //18x18
    begin
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}}; 
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}}; 
    end
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)                                         //36x18
    begin
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};
    end
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27 && MIN_DATA_SIZE > 18)                                         //27x27
    begin  
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    end
    else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)                                         //36x36
    begin   
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};    
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};    
    end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)                                         //54x18                                                 
    begin   
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};		
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{MIN_DATA_SIZE{1'b0}}};		
    end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)                                         //54x27  
    begin   
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)                                         //54x36  
    begin   
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};        
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};        
    end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE >36)                                          //54x54  
    begin    
        m_b0_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b0[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
        m_b1_sign_ext = {{m_b_sign_ext_bit{M_B_SIGNED && m_b1[MIN_DATA_SIZE-1]}},{(MIN_DATA_SIZE-m_b_data_lsb){1'b0}}};
    end
    else 
    begin    
        m_b0_sign_ext = 0;
        m_b1_sign_ext = 0;
    end
end

always@(*) begin
	if (MAX_DATA_SIZE <= 9)     //9x9
    begin
		m_b0_0[8:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b0[MIN_DATA_SIZE-1:0]};
		m_b1_0[8:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b1[MIN_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 9 && MAX_DATA_SIZE <= 18 && MIN_DATA_SIZE < 18)    //18x18
    begin    
		m_b0_0[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b0[MIN_DATA_SIZE-1:0]}; 
		m_b1_0[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b1[MIN_DATA_SIZE-1:0]}; 
    end
	else if (MAX_DATA_SIZE > 9 && MAX_DATA_SIZE <= 18 && MIN_DATA_SIZE == 18)   //18x18
    begin
		m_b0_0[17:0] = m_b0[MIN_DATA_SIZE-1:0];
		m_b1_0[17:0] = m_b1[MIN_DATA_SIZE-1:0];
    end
	else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE < 18)    //72x18or36x18or54x18
    begin
		m_b0_0[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b0[MIN_DATA_SIZE-1:0]};
		m_b1_0[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s:MIN_DATA_SIZE],m_b1[MIN_DATA_SIZE-1:0]};
    end
	else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=72 && MIN_DATA_SIZE ==18)    //72x18or36x18or54x18
    begin
		m_b0_0[17:0] = {{M_B_SIGNED&&m_b0[MIN_DATA_SIZE-1]},m_b0[MIN_DATA_SIZE-1:0]};
		m_b1_0[17:0] = {{M_B_SIGNED&&m_b1[MIN_DATA_SIZE-1]},m_b1[MIN_DATA_SIZE-1:0]};
    end
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <= 27 && MIN_DATA_SIZE > 18)   //27x27 
    begin
        m_b0_0[17:0] = m_b0[17:0];
        m_b1_0[17:0] = m_b1[17:0];
		m_b0_1[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_1[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <= 36&& MIN_DATA_SIZE > 18 && MIN_DATA_SIZE < 36  )    //36x36 
    begin
        m_b0_0[17:0] = m_b0[17:0];
        m_b1_0[17:0] = m_b1[17:0];
		m_b0_1[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_1[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
	else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <= 36&&  MIN_DATA_SIZE == 36  )    //36x36 
    begin
        m_b0_0[17:0] = m_b0[17:0];
        m_b1_0[17:0] = m_b1[17:0];
		m_b0_1[17:0] = {{M_B_SIGNED&&m_b0[MIN_DATA_SIZE-1]},m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_1[17:0] = {{M_B_SIGNED&&m_b1[MIN_DATA_SIZE-1]},m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE > 18 && MIN_DATA_SIZE <=27)  //54x27 
    begin
        m_b0_0[17:0] = m_b0[17:0];
        m_b1_0[17:0] = m_b1[17:0];
		m_b0_1[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_1[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE > 18 && MIN_DATA_SIZE < 36)  //54x36
    begin
        m_b0_0[17:0] = m_b0[17:0];
        m_b1_0[17:0] = m_b1[17:0];
		m_b0_1[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_1[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE ==36)    //54x36 
    begin
        m_b0_0[17:0] = m_b0[17:0];    
        m_b1_0[17:0] = m_b1[17:0];    
		m_b0_1[17:0] = {{M_B_SIGNED&&m_b0[MIN_DATA_SIZE-1]},m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_1[17:0] = {{M_B_SIGNED&&m_b1[MIN_DATA_SIZE-1]},m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 36 && MIN_DATA_SIZE < 54 )    //54x54 
    begin   
		m_b0_0[17:0] = m_b0[17:0];
		m_b1_0[17:0] = m_b1[17:0];
        m_b0_1[17:0] = m_b0[35:18];
        m_b1_1[17:0] = m_b1[35:18];
		m_b0_2[17:0] = {m_b0_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_2[17:0] = {m_b1_sign_ext[MIN_DATA_SIZE+m_b_sign_ext_bit_s-m_b_data_lsb:MIN_DATA_SIZE-m_b_data_lsb],m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
    else if (MAX_DATA_SIZE >45 && MAX_DATA_SIZE <= 54&& MIN_DATA_SIZE ==54 )    //54x54
    begin
		m_b0_0[17:0] = m_b0[17:0];
		m_b1_0[17:0] = m_b1[17:0];
        m_b0_1[17:0] = m_b0[35:18];
        m_b1_1[17:0] = m_b1[35:18];
		m_b0_2[17:0] = {{M_B_SIGNED&&m_b0[MIN_DATA_SIZE-1]},m_b0[MIN_DATA_SIZE-1:m_b_data_lsb]};
		m_b1_2[17:0] = {{M_B_SIGNED&&m_b1[MIN_DATA_SIZE-1]},m_b1[MIN_DATA_SIZE-1:m_b_data_lsb]};
	end
end 
//*******************************************************addsub***************************************************************
always@(posedge clk or posedge rst_async) 
begin
    if (rst_async) 
    begin
	   addsub_1d <= 0;
	   addsub_2d <= 0;
    end
    else if (rst_sync) 
    begin
	   addsub_1d <= 0;
	   addsub_2d <= 0;
    end
    else if (ce)
    begin
	   addsub_1d <= (DYN_ADDSUB_OP == 1)? addsub : ADDSUB_OP;
	   addsub_2d <= addsub_1d; 
    end
end

assign addsub_d1 = (PIPEREG_EN_2 == 1 && INREG_EN == 1) ? addsub_2d :
                   (INREG_EN     == 1) ? addsub_1d : 
                   (PIPEREG_EN_2 == 1) ? addsub_1d : (DYN_ADDSUB_OP == 1) ? addsub : ADDSUB_OP;

assign addsub_in[8:0] = {9{addsub_d1}};

//*******************************************************input data***********************************************************
always@(*)
begin
    if (MAX_DATA_SIZE <=9) //9x9
    begin 
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        modez_0 [0] = 1'b0;
    end
    else if (MAX_DATA_SIZE>9 && MAX_DATA_SIZE <=18) //18x18
    begin 
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        modez_0 [0] = 1'b0;
    end
    else if (MAX_DATA_SIZE >18 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE <=18) //36x18
    begin
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_1;
        m_a1_div[1] = m_a1_1;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_0;
        m_b1_div[1] = m_b1_0;
        modez_0[1:0] = 2'b10;
    end
    else if (MAX_DATA_SIZE >18 && MAX_DATA_SIZE <=27 && MIN_DATA_SIZE >18)  //27x27
    begin
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_0;
        m_a1_div[1] = m_a1_0;
        m_a0_div[2] = m_a0_1;
        m_a1_div[2] = m_a1_1;
        m_a0_div[3] = m_a0_1;
        m_a1_div[3] = m_a1_1;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_1;
        m_b1_div[1] = m_b1_1;
        m_b0_div[2] = m_b0_0;
        m_b1_div[2] = m_b1_0;
        m_b0_div[3] = m_b0_1;
        m_b1_div[3] = m_b1_1;
        modez_0[3:0] = 4'b1010;
    end
    else if (MAX_DATA_SIZE >27 && MAX_DATA_SIZE <= 36 && MIN_DATA_SIZE >=18) //36x36
    begin
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_0;
        m_a1_div[1] = m_a1_0;
        m_a0_div[2] = m_a0_1;
        m_a1_div[2] = m_a1_1;
        m_a0_div[3] = m_a0_1;
        m_a1_div[3] = m_a1_1;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_1;
        m_b1_div[1] = m_b1_1;
        m_b0_div[2] = m_b0_0;
        m_b1_div[2] = m_b1_0;
        m_b0_div[3] = m_b0_1;
        m_b1_div[3] = m_b1_1;
        modez_0[3:0] = 4'b1010;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE <=18) //54x18
    begin
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_1;
        m_a1_div[1] = m_a1_1;
        m_a0_div[2] = m_a0_2;
        m_a1_div[2] = m_a1_2;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_0;
        m_b1_div[1] = m_b1_0;
        m_b0_div[2] = m_b0_0;
        m_b1_div[2] = m_b1_0;
        modez_0[2:0] = 3'b110;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 18 && MIN_DATA_SIZE <=27) //54x27
    begin 
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_0;
        m_a1_div[1] = m_a1_0;
        m_a0_div[2] = m_a0_1;
        m_a1_div[2] = m_a1_1;
        m_a0_div[3] = m_a0_1;
        m_a1_div[3] = m_a1_1;
        m_a0_div[4] = m_a0_2;
        m_a1_div[4] = m_a1_2;
        m_a0_div[5] = m_a0_2;
        m_a1_div[5] = m_a1_2;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_1;
        m_b1_div[1] = m_b1_1;
        m_b0_div[2] = m_b0_0;
        m_b1_div[2] = m_b1_0;
        m_b0_div[3] = m_b0_1;
        m_b1_div[3] = m_b1_1;
        m_b0_div[4] = m_b0_0;
        m_b1_div[4] = m_b1_0;
        m_b0_div[5] = m_b0_1;
        m_b1_div[5] = m_b1_1;
        modez_0[5:0] = 6'b10_1010;
    end    
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 27 && MIN_DATA_SIZE <=36) //54x36
    begin 
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_0;
        m_a1_div[1] = m_a1_0;
        m_a0_div[2] = m_a0_1;
        m_a1_div[2] = m_a1_1;
        m_a0_div[3] = m_a0_1;
        m_a1_div[3] = m_a1_1;
        m_a0_div[4] = m_a0_2;
        m_a1_div[4] = m_a1_2;
        m_a0_div[5] = m_a0_2;
        m_a1_div[5] = m_a1_2;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_1;
        m_b1_div[1] = m_b1_1;
        m_b0_div[2] = m_b0_0;
        m_b1_div[2] = m_b1_0;
        m_b0_div[3] = m_b0_1;
        m_b1_div[3] = m_b1_1;
        m_b0_div[4] = m_b0_0;
        m_b1_div[4] = m_b1_0;
        m_b0_div[5] = m_b0_1;
        m_b1_div[5] = m_b1_1;
        modez_0[5:0] = 6'b10_1010;
    end
    else if (MAX_DATA_SIZE >36 && MAX_DATA_SIZE <= 54 && MIN_DATA_SIZE > 36) //54x54
    begin 
        m_a0_div[0] = m_a0_0;
        m_a1_div[0] = m_a1_0;
        m_a0_div[1] = m_a0_0;
        m_a1_div[1] = m_a1_0;
        m_a0_div[2] = m_a0_1;
        m_a1_div[2] = m_a1_1;
        m_a0_div[3] = m_a0_0;
        m_a1_div[3] = m_a1_0;
        m_a0_div[4] = m_a0_1;
        m_a1_div[4] = m_a1_1;
        m_a0_div[5] = m_a0_2;
        m_a1_div[5] = m_a1_2;
        m_a0_div[6] = m_a0_1;
        m_a1_div[6] = m_a1_1;
        m_a0_div[7] = m_a0_2;
        m_a1_div[7] = m_a1_2;
        m_a0_div[8] = m_a0_2;
        m_a1_div[8] = m_a1_2;
        m_b0_div[0] = m_b0_0;
        m_b1_div[0] = m_b1_0;
        m_b0_div[1] = m_b0_1;
        m_b1_div[1] = m_b1_1;
        m_b0_div[2] = m_b0_0;
        m_b1_div[2] = m_b1_0;
        m_b0_div[3] = m_b0_2;
        m_b1_div[3] = m_b1_2;
        m_b0_div[4] = m_b0_1;
        m_b1_div[4] = m_b1_1;
        m_b0_div[5] = m_b0_0;
        m_b1_div[5] = m_b1_0;
        m_b0_div[6] = m_b0_2;
        m_b1_div[6] = m_b1_2;
        m_b0_div[7] = m_b0_1;
        m_b1_div[7] = m_b1_1;
        m_b0_div[8] = m_b0_2;
        m_b1_div[8] = m_b1_2;
        modez_0[8:0] = 9'b1_0100_1010;
    end                  
end

genvar m_i;
generate
    for (m_i=0; m_i < GTP_APM_E1_GROUP_NUM; m_i=m_i+1)
    begin
        always@(posedge clk or posedge rst_async) 
        begin
            if (rst_async) 
            begin
                m_a0_div_ff[m_i]  <= 18'b0;  
                m_a1_div_ff[m_i]  <= 18'b0;  
                m_b0_div_ff[m_i]  <= 18'b0; 
                m_b1_div_ff[m_i]  <= 18'b0; 
            end
            else if (rst_sync) 
            begin
                m_a0_div_ff[m_i]  <= 18'b0;  
                m_a1_div_ff[m_i]  <= 18'b0;  
                m_b0_div_ff[m_i]  <= 18'b0;
                m_b1_div_ff[m_i]  <= 18'b0;
            end
            else
            begin
                m_a0_div_ff[m_i]  <= m_a0_div[m_i];  
                m_a1_div_ff[m_i]  <= m_a1_div[m_i];  
                m_b0_div_ff[m_i]  <= m_b0_div[m_i];   
                m_b1_div_ff[m_i]  <= m_b1_div[m_i];   
            end
        end
    end      
endgenerate

genvar data_in_i;
generate
    for (data_in_i=0; data_in_i < GTP_APM_E1_GROUP_NUM; data_in_i=data_in_i+1)
    begin
        assign m_a0_in[data_in_i] = (INREG_EN == 1) ? m_a0_div_ff[data_in_i] : m_a0_div[data_in_i];
        assign m_a1_in[data_in_i] = (INREG_EN == 1) ? m_a1_div_ff[data_in_i] : m_a1_div[data_in_i];
        assign m_b0_in[data_in_i] = (INREG_EN == 1) ? m_b0_div_ff[data_in_i] : m_b0_div[data_in_i];
        assign m_b1_in[data_in_i] = (INREG_EN == 1) ? m_b1_div_ff[data_in_i] : m_b1_div[data_in_i];
    end      
endgenerate

//************************************************************GTP*********************************************************
genvar i;
generate
    for (i=1; i< GTP_APM_E1_GROUP_NUM; i=i+1)
    begin
        GTP_APM_E1 #(
        .GRS_EN        ( GRS_EN              ),   
        .X_SIGNED      ( M_A_IN_SIGNED[i]    ),
        .Y_SIGNED      ( M_B_IN_SIGNED[i]    ),
        .USE_POSTADD   ( USE_POSTADD         ),     
        .X_REG         ( PIPEREG_EN_1        ),      
        .Y_REG         ( PIPEREG_EN_1        ),     
        .Z_REG         ( PIPEREG_EN_1        ),
        .MODEZ_REG     ( PIPEREG_EN_1        ),        
        .MULT_REG      ( PIPEREG_EN_2        ),     
        .P_REG         ( PIPEREG_EN_3        ),          
        .ASYNC_RST     ( ASYNC_RST           ),     
        .Z_INIT        ( 48'b0               ),     
        .CPO_REG       ( CPO_REG[i]          ),                                             
        .USE_SIMD      ( USE_SIMD            )      
	     )                              
        multadd_H(                                                                    
        .P      ( m_p[i]   ),       //Postadder resout                                     
        .CPO    ( cpo[(i*2+1)] ),      //P cascade out                        
        .COUT   (          ),      //Postadder carry out                  
        .CXO    (          ),      //X cascade out                        
        .CXBO   (          ),      //X backward cascade out               
        .X      ( m_a0_in[i]),                                                         
        .CXI    (          ),    //X cascade in                                       
        .CXBI   (          ),    //X backward cascade in                              
        .Y      ( m_b0_in[i]),                                                               
        .Z      ( 48'b1    ),
        .CPI    ( cpo[i*2] ),     //P cascade in
        .CIN    (          ),     //Postadder carry in
        .MODEX  ( 1'b0     ),     // preadder add/sub(), 0/1
        .MODEY  ( 3'b0     ),
        //ODEY encoding: 0/1
        //[0]     produce all-0 . to post adder / enable P register feedback. MODEY[1] needs to be 1 for MODEY[0] to take effect.
        //[1]     enable/disable mult . for post adder
        //[2]     +/- (mult-mux . polarity)
        .MODEZ  ( {addsub_in[i],3'b110} ),
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
        
        GTP_APM_E1 #(
        .GRS_EN        ( GRS_EN              ),   
        .X_SIGNED      ( M_A_IN_SIGNED[i]    ),
        .Y_SIGNED      ( M_B_IN_SIGNED[i]    ),
        .USE_POSTADD   ( USE_POSTADD         ),     
        .X_REG         ( PIPEREG_EN_1        ),      
        .Y_REG         ( PIPEREG_EN_1        ),     
        .Z_REG         ( PIPEREG_EN_1        ), 
        .MODEZ_REG     ( PIPEREG_EN_1        ),        
        .MULT_REG      ( PIPEREG_EN_2        ),     
        .P_REG         ( PIPEREG_EN_3        ),          
        .ASYNC_RST     ( ASYNC_RST           ),     
        .Z_INIT        ( 48'b0               ),     
        .CPO_REG       ( 1'b0                ),                                             
        .USE_SIMD      ( USE_SIMD            )      
	     )                              
        multadd_L(                                                                    
        .P      (          ),       //Postadder resout                                     
        .CPO    ( cpo[i*2] ),      //P cascade out                        
        .COUT   (          ),      //Postadder carry out                  
        .CXO    (          ),      //X cascade out                        
        .CXBO   (          ),      //X backward cascade out               
        .X      ( m_a1_in[i]),                                                         
        .CXI    (          ),    //X cascade in                                       
        .CXBI   (          ),    //X backward cascade in                              
        .Y      ( m_b1_in[i]),                                                               
        .Z      ( 48'b1    ),
        .CPI    ( cpo[(i-1)*2+1]   ),     //P cascade in
        .CIN    (          ),     //Postadder carry in
        .MODEX  ( 1'b0     ),     // preadder add/sub(), 0/1
        .MODEY  ( 3'b0     ),
        //ODEY encoding: 0/1
        //[0]     produce all-0 . to post adder / enable P register feedback. MODEY[1] needs to be 1 for MODEY[0] to take effect.
        //[1]     enable/disable mult . for post adder
        //[2]     +/- (mult-mux . polarity)
        .MODEZ  ( {addsub_in[i],2'b11,modez_0[i]} ),
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
        .Y_REG         ( PIPEREG_EN_1        ),     
        .Z_REG         ( PIPEREG_EN_1        ), 
        .MODEZ_REG     ( PIPEREG_EN_1        ),        
        .MULT_REG      ( PIPEREG_EN_2        ),     
        .P_REG         ( PIPEREG_EN_3        ),         
        .ASYNC_RST     ( ASYNC_RST           ),     
        .Z_INIT        ( 48'b0               ),     
        .CPO_REG       ( CPO_REG[0]          ),                                             
        .USE_SIMD      ( USE_SIMD            )      
	     )                              
        multadd_1(                                                                    
        .P      ( m_p[0]   ),       //Postadder resout                                     
        .CPO    ( cpo[1]   ),      //P cascade out                        
        .COUT   (          ),      //Postadder carry out                  
        .CXO    (          ),      //X cascade out                        
        .CXBO   (          ),      //X backward cascade out               
        .X      ( m_a0_in[0]),                                                         
        .CXI    (          ),    //X cascade in                                       
        .CXBI   (          ),    //X backward cascade in                              
        .Y      ( m_b0_in[0]),                                                               
        .Z      ( 48'b1    ),
        .CPI    ( cpo[0]   ),     //P cascade in
        .CIN    (          ),     //Postadder carry in
        .MODEX  ( 1'b0     ),     // preadder add/sub(), 0/1
        .MODEY  ( 3'b0     ),
        //ODEY encoding: 0/1
        //[0]     produce all-0 . to post adder / enable P register feedback. MODEY[1] needs to be 1 for MODEY[0] to take effect.
        //[1]     enable/disable mult . for post adder
        //[2]     +/- (mult-mux . polarity)
        .MODEZ  ( {addsub_in[0],3'b110} ),
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

     GTP_APM_E1 #(
        .GRS_EN        ( GRS_EN              ),   
        .X_SIGNED      ( M_A_IN_SIGNED[0]    ),
        .Y_SIGNED      ( M_B_IN_SIGNED[0]    ),
        .USE_POSTADD   ( USE_POSTADD         ),     
        .X_REG         ( PIPEREG_EN_1        ),       
        .Y_REG         ( PIPEREG_EN_1        ),     
        .Z_REG         ( PIPEREG_EN_1        ), 
        .MODEZ_REG     ( PIPEREG_EN_1        ),        
        .MULT_REG      ( PIPEREG_EN_2        ),     
        .P_REG         ( PIPEREG_EN_3        ),          
        .ASYNC_RST     ( ASYNC_RST           ),     
        .Z_INIT        ( 48'b0               ),     
        .CPO_REG       ( 1'b0                ),                                             
        .USE_SIMD      ( USE_SIMD            )      
	     )                              
        multadd_0(                                                                    
        .P      (        ),     //Postadder resout                                     
        .CPO    ( cpo[0] ),     //P cascade out                        
        .COUT   (        ),     //Postadder carry out                  
        .CXO    (        ),     //X cascade out                        
        .CXBO   (        ),     //X backward cascade out               
        .X      ( m_a1_in[0]),                                                         
        .CXI    (        ),     //X cascade in                                       
        .CXBI   (        ),     //X backward cascade in                              
        .Y      ( m_b1_in[0]),                                                               
        .Z      ( 48'b1  ),     
        .CPI    (        ),     //P cascade in
        .CIN    (        ),     //Postadder carry in
        .MODEX  ( 1'b0   ),     // preadder add/sub(), 0/1
        .MODEY  ( 3'b0   ),
        .MODEZ  ( {3'b0,modez_0[0]}   ),
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
        m_p_o[18:0] = m_p[0][18:0]; 
    else if (MAX_DATA_SIZE <=18 && MIN_DATA_SIZE <= 18)  //18x18     
        m_p_o[36:0] = m_p[0][36:0];  
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE <=18)    //36x18
        m_p_o[54:0] = {m_p[1][36:0],m_p[0][17:0]}; 
    else if (MAX_DATA_SIZE > 18 && MAX_DATA_SIZE <=27 && MIN_DATA_SIZE > 18)    //27x27
        m_p_o[72:0] = {m_p[3][36:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 27 && MAX_DATA_SIZE <=36 && MIN_DATA_SIZE > 18)    //36x36
        m_p_o[72:0] = {m_p[3][36:0],m_p[2][17:0],m_p[0][17:0]};  
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=18)    //54x18                                                 
        m_p_o[72:0] = {m_p[2][36:0],m_p[1][17:0],m_p[0][17:0]};		
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=27)    //54x27  
        m_p_o[90:0] = {m_p[5][36:0],m_p[4][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE <=36)    //54x36  
        m_p_o[90:0] = {m_p[5][36:0],m_p[4][17:0],m_p[2][17:0],m_p[0][17:0]};
    else if (MAX_DATA_SIZE > 36 && MAX_DATA_SIZE <=54 && MIN_DATA_SIZE > 36)    //54x54  
        m_p_o[108:0] = {m_p[8][36:0],m_p[7][17:0],m_p[5][17:0],m_p[2][17:0],m_p[0][17:0]};
    else 
        m_p_o[108:0] = 108'b0; 
end

//**************************************************************output reg***********************************************************
  
always@(posedge clk or posedge rst_async) 
begin
    if (rst_async) 
        m_p_o_ff <= 108'b0;
    else if (rst_sync) 
        m_p_o_ff <= 108'b0;
    else
        m_p_o_ff <= m_p_o;
end

assign p = (OUTREG_EN == 1) ? m_p_o_ff[PSIZE-1:0] : m_p_o[PSIZE-1:0];

endmodule
