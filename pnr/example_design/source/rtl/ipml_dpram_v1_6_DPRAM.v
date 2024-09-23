

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
// Filename:ipml_dpram.v
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module ipml_dpram_v1_6_DPRAM
  #(
    parameter  c_SIM_DEVICE              = "LOGOS"       ,
    parameter  c_A_ADDR_WIDTH            = 10            ,  //write address width  legal value:9~20
    parameter  c_A_DATA_WIDTH            = 32            ,  //write data width     1)c_WR_BYTE_EN =0 legal value:1~1152  2)c_WR_BYTE_EN=1  legal value:2^N or 9*2^N
    parameter  c_B_ADDR_WIDTH            = 10            ,  //read address width   legal value:9~20
    parameter  c_B_DATA_WIDTH            = 32            ,  //read data width      1)c_WR_BYTE_EN =0 legal value:1~1152  2)c_WR_BYTE_EN=1  legal value:2^N or 9*2^N
    parameter  c_A_OUTPUT_REG            = 0             ,  //port A output register      legal value: 0 or 1
    parameter  c_A_RD_OCE_EN             = 0             ,  //port A rd_oce enable
    parameter  c_A_ADDR_STROBE_EN        = 0             ,
    parameter  c_A_CLK_EN                = 0             ,
    parameter  c_B_OUTPUT_REG            = 0             ,  //PORT B output register      legal value: 1 or 0
    parameter  c_B_RD_OCE_EN             = 0             ,  //port B rd_oce enable
    parameter  c_B_ADDR_STROBE_EN        = 0             ,
    parameter  c_B_CLK_EN                = 0             ,
    parameter  c_RESET_TYPE              = "ASYNC_RESET" ,  //reset type legal valve "ASYNC_RESET_SYNC_RELEASE" "SYNC_RESET" "ASYNC_RESET"
    parameter  c_A_CLK_OR_POL_INV        = 0             ,  //clk polarity invert for output register    legal value: 1 or 0
    parameter  c_B_CLK_OR_POL_INV        = 0             ,  //clk polarity invert for output register    legal value: 1 or 0
    parameter  c_POWER_OPT               = 0             ,  //0 :normal mode  1:low power mode legal value: 1 or 0
    parameter  c_INIT_FILE               = "NONE"        ,  //legal value:"NONE" or "initial file name"
    parameter  c_INIT_FORMAT             = "BIN"         ,  //legal value "bin" or "hex"
    parameter  c_WR_BYTE_EN              = 0             ,  //legal value: 0 or 1
    parameter  c_A_BE_WIDTH              = 8             ,  //PORT A byte write width  legal value: 1~128
    parameter  c_B_BE_WIDTH              = 8             ,  //PORT B byte write width  legal value: 1~128
    parameter  c_A_WRITE_MODE            = "NORMAL_WRITE",  //legal value "TRANSPARENT_WRITE" "READ_BEFORE_WRITE"
    parameter  c_B_WRITE_MODE            = "NORMAL_WRITE"  //legal value "TRANSPARENT_WRITE" "READ_BEFORE_WRITE"
   )
   (
    input  wire [c_A_ADDR_WIDTH-1 : 0]  a_addr        ,
    input  wire [c_A_DATA_WIDTH-1 : 0]  a_wr_data     ,
    output wire [c_A_DATA_WIDTH-1 : 0]  a_rd_data     ,
    input  wire                         a_wr_en       ,
    input  wire                         a_clk         ,
    input  wire                         a_clk_en      ,
    input  wire                         a_rst         ,
    input  wire [c_A_BE_WIDTH-1 : 0]    a_wr_byte_en  ,
    input  wire                         a_rd_oce      ,
    input  wire                         a_addr_strobe ,
                                        
    input  wire [c_B_ADDR_WIDTH-1 : 0]  b_addr        ,
    input  wire [c_B_DATA_WIDTH-1 : 0]  b_wr_data     ,
    output wire [c_B_DATA_WIDTH-1 : 0]  b_rd_data     ,
    input  wire                         b_wr_en       ,
    input  wire                         b_clk         ,
    input  wire                         b_clk_en      ,
    input  wire                         b_rst         ,
    input  wire [c_B_BE_WIDTH-1:0]      b_wr_byte_en  ,
    input  wire                         b_rd_oce      ,
    input  wire                         b_addr_strobe 
   );


localparam MODE_9K = 0 ; // @IPC bool

localparam MODE_18K = 1 ; // @IPC bool

localparam INIT_EN = 0 ; // @IPC bool

   
//

//********************************************************************************************************************************************************************   
//declare localparam
//********************************************************************************************************************************************************************
//parameter  check
localparam  c_WR_BYTE_WIDTH = c_WR_BYTE_EN ? c_A_DATA_WIDTH/(c_A_BE_WIDTH==0 ? 1 : c_A_BE_WIDTH) : ( (c_A_DATA_WIDTH%9) == 0 ? 9 : (c_A_DATA_WIDTH%8 == 0) ? 8 : 9 );
//c_A_DATA_WIDTH == 2^N
//WIDTH_RATIO = 1 
//L_DATA_WIDTH is the parameter value of DATA_WIDTH_A and DATA_WIDTH_B in a instance DRM ,define witch type DRM to instance in noraml mode
localparam  DATA_WIDTH_WIDE  = (c_A_DATA_WIDTH >= c_B_DATA_WIDTH) ? c_A_DATA_WIDTH :c_B_DATA_WIDTH ;    //wider DATA_WIDTH between c_WR_DATA_WIDTH and c_RD_DATA_WIDTH 
localparam  ADDR_WIDTH_WIDE  = (c_A_DATA_WIDTH >= c_B_DATA_WIDTH) ? c_A_ADDR_WIDTH :c_B_ADDR_WIDTH ;    //ADDR WIDTH correspond to DATA_WIDTH_WIDE

localparam  N_DATA_1_WIDTH   =  (ADDR_WIDTH_WIDE <= 10) ? ((DATA_WIDTH_WIDE%9) == 0 ? 18 : (DATA_WIDTH_WIDE%8) == 0 ? 16 : 18) :       //cascade with 1k*18  type DRM 
                                (ADDR_WIDTH_WIDE == 11) ? ((DATA_WIDTH_WIDE%9) == 0 ? 9 :  (DATA_WIDTH_WIDE%8) == 0 ? 8  : 9 ) :        //cascade with 2k*9   type DRM 
                                (ADDR_WIDTH_WIDE == 12) ? 4:                                            //cascade with 4k*4   type DRM 
                                (ADDR_WIDTH_WIDE == 13) ? 2:                                            //cascade with 8k*2   type DRM 
                                                        1;                                              //cascade with 16k*1  type DRM

localparam  L_DATA_1_WIDTH   =  (DATA_WIDTH_WIDE == 1)  ? 1:                                            //cascade with 16k*1  type DRM 
                                (DATA_WIDTH_WIDE == 2)  ? 2:                                            //cascade with 8k*2   type DRM 
                                (DATA_WIDTH_WIDE <= 4)  ? 4:                                            //cascade with 2k*9   type DRM 
                                (DATA_WIDTH_WIDE <= 9)  ? ((DATA_WIDTH_WIDE%9) == 0 ? 9  : (DATA_WIDTH_WIDE%8) == 0 ? 8  : 9 ) :         //cascade with 4k*4   type DRM 
                                                          ((DATA_WIDTH_WIDE%9) == 0 ? 18 : (DATA_WIDTH_WIDE%8) == 0 ? 16 : 18) ;         //cascade with 1k*18  type DRM
//WIDTH_RATIO = 2
localparam  N_DATA_WIDTH_2_WIDE   =  ((DATA_WIDTH_WIDE%9) == 0) ?  18 :
                                       ((ADDR_WIDTH_WIDE <= 10) ?  16 :
                                        (ADDR_WIDTH_WIDE == 11) ?  8  :
                                        (ADDR_WIDTH_WIDE == 12) ?  4  :
                                                                   2 );

localparam  L_DATA_WIDTH_2_WIDE   =  ((DATA_WIDTH_WIDE%9) == 0) ? 18 :
                                     ((DATA_WIDTH_WIDE == 2)  ? 2  :
                                      (DATA_WIDTH_WIDE == 4)  ? 4  :
                                      (DATA_WIDTH_WIDE == 8)  ? 8  :
                                                                16);
//WIDTH_RATIO == 4
localparam  N_DATA_WIDTH_4_WIDE   =  ADDR_WIDTH_WIDE <= 10 ? 16:
                                     ADDR_WIDTH_WIDE == 11 ? 8 :
                                                             4 ;

localparam  L_DATA_WIDTH_4_WIDE   =  (DATA_WIDTH_WIDE == 4) ? 4 :
                                     (DATA_WIDTH_WIDE == 8) ? 8 :
                                                              16;

//WIDTH_RATIO == 8
localparam  N_DATA_WIDTH_8_WIDE   =  (ADDR_WIDTH_WIDE <= 10) ? 16:
                                                               8;

localparam  L_DATA_WIDTH_8_WIDE   =  (DATA_WIDTH_WIDE == 8)  ? 8:
                                                               16;
//WIDTH_RATIO == 16 
localparam  N_DATA_WIDTH_16_WIDE  =  16;

localparam  L_DATA_WIDTH_16_WIDE  =  16;
//********************************************************************************************************************************************************************
//BYTE ENABLE parameter 
//byte_enable==1 && WIDTH_RATIO = 1
localparam  N_BYTE_DATA_1_WIDTH = (c_WR_BYTE_WIDTH == 8) ? 16 : 18;

localparam  L_BYTE_DATA_1_WIDTH = (c_WR_BYTE_WIDTH == 8) ? 16 : 18;
//byte_enable==1 && WIDTH_RATIO = 2
localparam  N_BYTE_DATA_WIDTH_2_WIDE = (c_WR_BYTE_WIDTH == 8) ? 16 : 18;

localparam  L_BYTE_DATA_WIDTH_2_WIDE = (c_WR_BYTE_WIDTH == 8) ? 16 : 18;

//********************************************************************************************************************************************************************
localparam  WIDTH_RATIO  =  (c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? (c_A_DATA_WIDTH/c_B_DATA_WIDTH) : (c_B_DATA_WIDTH/c_A_DATA_WIDTH);

localparam  N_DRM_DATA_WIDTH_A  = (WIDTH_RATIO == 1)  ? N_DATA_1_WIDTH :
                                  (WIDTH_RATIO == 2)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_2_WIDE  : (N_DATA_WIDTH_2_WIDE/2)   ):
                                  (WIDTH_RATIO == 4)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_4_WIDE  : (N_DATA_WIDTH_4_WIDE/4)   ):
                                  (WIDTH_RATIO == 8)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_8_WIDE  : (N_DATA_WIDTH_8_WIDE/8)   ):
                                                        ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_16_WIDE : (N_DATA_WIDTH_16_WIDE/16) );

localparam  L_DRM_DATA_WIDTH_A  = (WIDTH_RATIO == 1)  ? L_DATA_1_WIDTH :
                                  (WIDTH_RATIO == 2)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_2_WIDE  : (L_DATA_WIDTH_2_WIDE/2)   ):
                                  (WIDTH_RATIO == 4)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_4_WIDE  : (L_DATA_WIDTH_4_WIDE/4)   ):
                                  (WIDTH_RATIO == 8)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_8_WIDE  : (L_DATA_WIDTH_8_WIDE/8)   ):
                                                        ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_16_WIDE : (L_DATA_WIDTH_16_WIDE/16) );

localparam  N_DRM_DATA_WIDTH_B  = (WIDTH_RATIO == 1)  ? N_DATA_1_WIDTH :
                                  (WIDTH_RATIO == 2)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_2_WIDE  : (N_DATA_WIDTH_2_WIDE/2)   ):
                                  (WIDTH_RATIO == 4)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_4_WIDE  : (N_DATA_WIDTH_4_WIDE/4)   ):
                                  (WIDTH_RATIO == 8)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_8_WIDE  : (N_DATA_WIDTH_8_WIDE/8)   ):
                                                        ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_16_WIDE : (N_DATA_WIDTH_16_WIDE/16) );

localparam  L_DRM_DATA_WIDTH_B  = (WIDTH_RATIO == 1)  ? L_DATA_1_WIDTH :
                                  (WIDTH_RATIO == 2)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_2_WIDE  : (L_DATA_WIDTH_2_WIDE/2)   ):
                                  (WIDTH_RATIO == 4)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_4_WIDE  : (L_DATA_WIDTH_4_WIDE/4)   ):
                                  (WIDTH_RATIO == 8)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_8_WIDE  : (L_DATA_WIDTH_8_WIDE/8)   ):
                                                        ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_16_WIDE : (L_DATA_WIDTH_16_WIDE/16) );

//********************************************************************************************************************************************************************
//byte_enable  DRM DATA WIDTH 
localparam  N_BYTE_DATA_WIDTH_A = (WIDTH_RATIO == 1)  ? N_BYTE_DATA_1_WIDTH :
                                                        ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_BYTE_DATA_WIDTH_2_WIDE  : (N_BYTE_DATA_WIDTH_2_WIDE/2));

localparam  L_BYTE_DATA_WIDTH_A = (WIDTH_RATIO == 1)  ? L_BYTE_DATA_1_WIDTH :
                                                        ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_BYTE_DATA_WIDTH_2_WIDE  : (L_BYTE_DATA_WIDTH_2_WIDE/2));

localparam  N_BYTE_DATA_WIDTH_B = (WIDTH_RATIO == 1)  ? N_BYTE_DATA_1_WIDTH :
                                                        ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_BYTE_DATA_WIDTH_2_WIDE  : (N_BYTE_DATA_WIDTH_2_WIDE/2));

localparam  L_BYTE_DATA_WIDTH_B = (WIDTH_RATIO == 1)  ? L_BYTE_DATA_1_WIDTH :
                                                        ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_BYTE_DATA_WIDTH_2_WIDE  : (L_BYTE_DATA_WIDTH_2_WIDE/2));
//*****************************************************************************************************************************************
//DRM_DATA_WIDTH_A is the  port A parameter  of DRM
localparam  DRM_DATA_WIDTH_A  = (c_POWER_OPT == 1) ? ((c_WR_BYTE_EN ==1) ? L_BYTE_DATA_WIDTH_A : L_DRM_DATA_WIDTH_A):
                                                     ((c_WR_BYTE_EN ==1) ? N_BYTE_DATA_WIDTH_A : N_DRM_DATA_WIDTH_A);
//DRM_DATA_WIDTH_A is the  port B parameter  of DRM
localparam  DRM_DATA_WIDTH_B  = (c_POWER_OPT == 1) ? ((c_WR_BYTE_EN ==1) ? L_BYTE_DATA_WIDTH_B : L_DRM_DATA_WIDTH_B):
                                                     ((c_WR_BYTE_EN ==1) ? N_BYTE_DATA_WIDTH_B : N_DRM_DATA_WIDTH_B);
//DATA_LOOP_NUM difine how many loop to cascade the c_A_DATA_WIDTH 
localparam  DATA_LOOP_NUM   = (c_A_DATA_WIDTH%DRM_DATA_WIDTH_A == 0) ? (c_A_DATA_WIDTH/DRM_DATA_WIDTH_A):(c_A_DATA_WIDTH/DRM_DATA_WIDTH_A + 1);

//DRM_ADDR_WIDTH is the ADDR_WIDTH of INSTANCE DRM primitives 
localparam  DRM_ADDR_WIDTH_A = (DRM_DATA_WIDTH_A == 1 ) ? 14:
                               (DRM_DATA_WIDTH_A == 2 ) ? 13:
                               (DRM_DATA_WIDTH_A == 4 ) ? 12:
                               (DRM_DATA_WIDTH_A == 8 ) ? 11:
                               (DRM_DATA_WIDTH_A == 9 ) ? 11:
                               (DRM_DATA_WIDTH_A == 16) ? 10:
                                                          10;

localparam  DRM_ADDR_WIDTH_B = (DRM_DATA_WIDTH_B == 1 ) ? 14:
                               (DRM_DATA_WIDTH_B == 2 ) ? 13:
                               (DRM_DATA_WIDTH_B == 4 ) ? 12:
                               (DRM_DATA_WIDTH_B == 8 ) ? 11:
                               (DRM_DATA_WIDTH_B == 9 ) ? 11:
                               (DRM_DATA_WIDTH_B == 16) ? 10:
                                                          10;

localparam  ADDR_WIDTH_A     = (c_A_ADDR_WIDTH > DRM_ADDR_WIDTH_A) ? c_A_ADDR_WIDTH : DRM_ADDR_WIDTH_A;
//CS_ADDR_WIDTH_A is the CS address width to choose the DRM18K CS_ADDR_WIDTH_A=  [ extra-addres + cs[2]+csp[1]+cs[0] ]
localparam  CS_ADDR_WIDTH_A  = ADDR_WIDTH_A - DRM_ADDR_WIDTH_A; //CS mean select

localparam  ADDR_WIDTH_B     = (c_B_ADDR_WIDTH > DRM_ADDR_WIDTH_B) ? c_B_ADDR_WIDTH : DRM_ADDR_WIDTH_B;
localparam  CS_ADDR_WIDTH_B  = ADDR_WIDTH_B - DRM_ADDR_WIDTH_B;
//ADDR_LOOP_NUM_A difine how many loops to cascade the c_A_ADDR_WIDTH
localparam  ADDR_LOOP_NUM_A  = 2**CS_ADDR_WIDTH_A;
localparam  ADDR_LOOP_NUM_B  = 2**CS_ADDR_WIDTH_B;

//CAS_DATA_WIDTH_A is the cascaded  data width 
localparam  CAS_DATA_WIDTH_A  =  DRM_DATA_WIDTH_A*DATA_LOOP_NUM ;  //CAS mean cascade
localparam  CAS_DATA_WIDTH_B  =  DRM_DATA_WIDTH_B*DATA_LOOP_NUM ;

localparam  A_WR_BYTE_WIDTH   =  (c_WR_BYTE_EN == 1) ? c_WR_BYTE_WIDTH :
                                 (((DRM_DATA_WIDTH_A >=8) || (DRM_DATA_WIDTH_A >=9)) ? ((c_A_DATA_WIDTH%9 == 0) ? 9 : 8 ) : 1 );
localparam  B_WR_BYTE_WIDTH   =  (c_WR_BYTE_EN == 1) ? c_WR_BYTE_WIDTH :
                                 (((DRM_DATA_WIDTH_B >=8) || (DRM_DATA_WIDTH_B >=9)) ? ((c_B_DATA_WIDTH%9 == 0) ? 9 : 8 ) : 1 );
//MASK_NUM the mask base value 
localparam  MASK_NUM_A  = ((DRM_DATA_WIDTH_A == 36) || (DRM_DATA_WIDTH_A == 32)) ? ((ADDR_LOOP_NUM_A > 4) ? 2 : 4 ) :
                                                            (ADDR_LOOP_NUM_A >8) ? (((DRM_DATA_WIDTH_A == 36) || (DRM_DATA_WIDTH_A == 32))
                                                                                 ? 2 : 4) : 8;

localparam  MASK_NUM_B  = ((DRM_DATA_WIDTH_B == 36) || (DRM_DATA_WIDTH_B == 32)) ? ((ADDR_LOOP_NUM_B > 4) ? 2 : 4 ) :
                                                           (ADDR_LOOP_NUM_B > 8) ? (((DRM_DATA_WIDTH_B == 36) || (DRM_DATA_WIDTH_B == 32))
                                                                                 ? 2 : 4) : 8;

localparam c_RST_TYPE = (c_RESET_TYPE == "SYNC_RESET") ? "SYNC" : ((c_RESET_TYPE == "ASYNC_RESET") ?  "ASYNC" : "ASYNC_SYNC_RELEASE");      

initial begin

   if( (2**c_A_ADDR_WIDTH*c_A_DATA_WIDTH) != (2**c_B_ADDR_WIDTH*c_B_DATA_WIDTH) ) begin
      $display("IPSpecCheck: 01030001 ipml_flex_dpram parameter setting error !!!: 2**c_A_ADDR_WIDTH*c_A_DATA_WIDTH must be equal to 2**c_B_ADDR_WIDTH*c_B_DATA_WIDTH")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if( c_A_ADDR_WIDTH>20  || c_A_ADDR_WIDTH<9 ) begin
      $display("IPSpecCheck: 01030002 ipml_flex_dpram parameter setting error !!!: c_A_ADDR_WIDTH must between 9-20")/* PANGO PAP_CRITICAL_WARNING */;
      //$finish;
   end 
   else if( c_A_DATA_WIDTH>1152  || c_A_DATA_WIDTH<1 ) begin
      $display("IPSpecCheck: 01030003 ipml_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH must between 1-1152")/* PANGO PAP_CRITICAL_WARNING */;
      //$finish;
   end
   else if( c_B_ADDR_WIDTH>20  || c_B_ADDR_WIDTH<9 ) begin
      $display("IPSpecCheck: 01030004 ipml_flex_dpram parameter setting error !!!: c_B_ADDR_WIDTH must between 9-20")/* PANGO PAP_CRITICAL_WARNING */;
      //$finish;
   end 
   else if( c_B_DATA_WIDTH>1152  || c_B_DATA_WIDTH <1 ) begin
      $display("IPSpecCheck: 01030005 ipml_flex_dpram parameter setting error !!!: c_B_DATA_WIDTH must between 1-1152")/* PANGO PAP_CRITICAL_WARNING */;
      //$finish;
   end 
   else if( (c_A_OUTPUT_REG!=1 && c_A_OUTPUT_REG!=0) || (c_B_OUTPUT_REG!=1 && c_B_OUTPUT_REG!=0) ) begin
      $display("IPSpecCheck: 01030007 ipml_flex_dpram parameter setting error !!!: c_A_OUTPUT_REG or c_B_OUTPUT_REG must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end 
   else if( (c_A_RD_OCE_EN!=1 && c_A_RD_OCE_EN!=0) || (c_B_RD_OCE_EN!=1 && c_B_RD_OCE_EN!=0) ) begin
      $display("IPSpecCheck: 01030008 ipml_flex_dpram parameter setting error !!!: c_A_RD_OCE_EN or c_B_RD_OCE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if( (c_A_CLK_OR_POL_INV!=1 && c_A_CLK_OR_POL_INV!=0 ) || (c_B_CLK_OR_POL_INV!=1 && c_B_CLK_OR_POL_INV!=0) ) begin
      $display("IPSpecCheck: 01030009 ipml_flex_dpram parameter setting error !!!: c_A_CLK_OR_POL_INV or c_B_CLK_OR_POL_INV must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end 
   else if( (c_A_RD_OCE_EN==1 && c_A_OUTPUT_REG==0) || (c_B_RD_OCE_EN==1 && c_B_OUTPUT_REG==0) ) begin
      $display("IPSpecCheck: 01030010 ipml_flex_dpram parameter setting error !!!: c_A_OUTPUT_REG or c_B_OUTPUT_REG must be 1 when c_A_RD_OCE_EN or c_B_RD_OCE_EN is 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if( (c_A_CLK_OR_POL_INV==1 && c_A_OUTPUT_REG==0) || (c_B_CLK_OR_POL_INV==1 && c_B_OUTPUT_REG==0) ) begin
      $display("IPSpecCheck: 01030011 ipml_flex_dpram parameter setting error !!!: c_A_OUTPUT_REG or c_B_OUTPUT_REG must be 1 when c_A_CLK_OR_POL_INV or c_B_CLK_OR_POL_INV is 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if ( (c_A_CLK_EN!=0 && c_A_CLK_EN!=1) || (c_B_CLK_EN!=0 && c_B_CLK_EN!=1) ) begin
      $display("IPSpecCheck: 01030012 ipml_flex_dpram parameter setting error !!!: c_A_CLK_EN or c_B_CLK_EN must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if ( (c_A_ADDR_STROBE_EN!=0 && c_A_ADDR_STROBE_EN!=1) || (c_B_ADDR_STROBE_EN!=0 && c_B_ADDR_STROBE_EN!=1) ) begin
      $display("IPSpecCheck: 01030013 ipml_flex_dpram parameter setting error !!!: c_A_ADDR_STROBE_EN or c_B_ADDR_STROBE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if ( c_SIM_DEVICE=="PGL22G" && ((c_A_CLK_EN==1 && c_A_ADDR_STROBE_EN==1) || (c_B_CLK_EN==1 && c_B_ADDR_STROBE_EN==1)) ) begin
      $display("IPSpecCheck: 01030014 ipml_flex_dpram parameter setting error !!!: Clock Enable and Address Strobe only works individually when using PGL22G")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if(c_RST_TYPE!="ASYNC" && c_RST_TYPE!="SYNC" && c_RST_TYPE!="ASYNC_SYNC_RELEASE") begin
      $display("IPSpecCheck: 01030015 ipml_flex_dpram parameter setting error !!!: c_RESET_TYPE must be ASYNC or SYNC or ASYNC_SYNC_RELEASE")/* PANGO PAP_ERROR */;
      $finish;
   end 
   else if(c_POWER_OPT!=1 && c_POWER_OPT!=0 ) begin
      $display("IPSpecCheck: 01030016 ipml_flex_dpram parameter setting error !!!: c_POWER_OPT must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end 
   else if(c_INIT_FORMAT!="BIN" && c_INIT_FORMAT!="HEX" ) begin
      $display("IPSpecCheck: 01030017 ipml_flex_dpram parameter setting error !!!: c_INIT_FORMAT must be bin or hex ")/* PANGO PAP_ERROR */;
      $finish;
   end 
   else if(c_WR_BYTE_EN!=0 && c_WR_BYTE_EN!=1 ) begin
      $display("IPSpecCheck: 01030018 ipml_flex_dpram parameter setting error !!!: c_WR_BYTE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if(c_WR_BYTE_EN==1) begin
       if(c_WR_BYTE_WIDTH!=8 &&  c_WR_BYTE_WIDTH!=9 ) begin
         $display("IPSpecCheck: 01030019 ipml_flex_dpram parameter setting error !!!: c_WR_BYTE_WIDTH must be 8 or 9")/* PANGO PAP_ERROR */;
         $finish;
      end
      if( (c_A_DATA_WIDTH%8)!=0 && (c_B_DATA_WIDTH%9)!=0 ) begin
         $display("IPSpecCheck: 01030020 ipml_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH must be 8*N or 9*N")/* PANGO PAP_ERROR */;
         $finish;
      end	
   end
   else if(c_A_WRITE_MODE!="NORMAL_WRITE" && c_A_WRITE_MODE!="TRANSPARENT_WRITE" && c_A_WRITE_MODE!="READ_BEFORE_WRITE") begin
         $display("IPSpecCheck: 01030021 ipml_flex_dpram parameter setting error !!!: c_A_WRITE_MODE must be NORMAL_WRITE or TRANSPARENT_WRITE or READ_BEFORE_WRITE")/* PANGO PAP_ERROR */;
         $finish;
   end
   else if(c_B_WRITE_MODE!="NORMAL_WRITE" && c_B_WRITE_MODE!="TRANSPARENT_WRITE" && c_B_WRITE_MODE!="READ_BEFORE_WRITE") begin
         $display("IPSpecCheck: 01030022 ipml_flex_dpram parameter setting error !!!: c_B_WRITE_MODE must be NORMAL_WRITE or TRANSPARENT_WRITE or READ_BEFORE_WRITE")/* PANGO PAP_ERROR */;
         $finish;
   end 
   else if ( c_A_WRITE_MODE=="READ_BEFORE_WRITE" && c_B_WRITE_MODE=="READ_BEFORE_WRITE" && c_SIM_DEVICE=="PGL22G") begin
      $display("IPSpecCheck: 01030027 ipml_flex_dpram parameter setting error !!!: Write Mode on both side could not be READ BEFORE WRITE at same time")/* PANGO PAP_CRITICAL_WARNING */;
      //$finish;
   end
   else if ( (c_WR_BYTE_EN == 1) && (c_A_ADDR_STROBE_EN==1 || c_B_ADDR_STROBE_EN==1) ) begin
      $display("IPSpecCheck: 01030028 ipml_flex_dpram parameter setting error !!!: When Byte Write, disable Address Strobe")/* PANGO PAP_ERROR */;
      $finish;
   end  
   else if( ((WIDTH_RATIO > 16) && (c_WR_BYTE_EN == 0)) ) begin
      $display("IPSpecCheck: 01030023 ipml_flex_dpram parameter setting error !!!: Data Width Ratio is 1~16 when disable Byte Write")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if( ((WIDTH_RATIO > 2) && (c_WR_BYTE_EN == 1)) ) begin
      $display("IPSpecCheck: 01030024 ipml_flex_dpram parameter setting error !!!: Data Width Ratio is 1~2 when enable Byte Write")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if ( c_POWER_OPT==0 && WIDTH_RATIO>1 ) begin
      $display("IPSpecCheck: 01030025 ipml_flex_dpram parameter setting error !!!: Mixed Data Width only works when c_POWER_OPT is 1")/* PANGO PAP_ERROR */;
      $finish;
   end
   else if ( WIDTH_RATIO>1 && c_INIT_FILE!="NONE" ) begin
      $display("IPSpecCheck: 01030026 ipml_flex_dpram parameter setting error !!!: No RAM Initial when Mixed Data Width")/* PANGO PAP_ERROR */;
      $finish;
   end   
   else if(c_A_DATA_WIDTH != c_B_DATA_WIDTH) begin
      if( c_A_DATA_WIDTH%9 == 0 || c_B_DATA_WIDTH%9 == 0 ) begin
         if ( (c_A_DATA_WIDTH/9)&(c_A_DATA_WIDTH/9-1) || (c_B_DATA_WIDTH/9)&(c_B_DATA_WIDTH/9-1) ) begin
            $display("IPSpecCheck: 01030000 ipml_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH and c_B_DATA_WIDTH must be 2^N or 9*2^N")/* PANGO PAP_ERROR */;
            $finish;
         end
         else if( ((WIDTH_RATIO > 2) && (c_WR_BYTE_EN == 0)) ) begin
            $display("IPSpecCheck: 01030029 ipml_flex_dpram parameter setting error !!!: Data Width Ratio is 1~2 when c_A_DATA_WIDTH and c_B_DATA_WIDTH is 9*2^N")/* PANGO PAP_ERROR */;
            $finish;
         end
      end
      else begin
         if ( c_A_DATA_WIDTH&(c_A_DATA_WIDTH-1) || c_B_DATA_WIDTH&(c_B_DATA_WIDTH-1) ) begin
            $display("IPSpecCheck: 01030000 ipml_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH and c_B_DATA_WIDTH must be 2^N or 9*2^N")/* PANGO PAP_ERROR */;
            $finish;
         end
      end
   end
end

//main code
//*************************************************************************************************************************************
//inner variables 
wire  [CAS_DATA_WIDTH_A-1:0]                  a_wr_data_bus    ;
reg   [CAS_DATA_WIDTH_A-1:0]                  a_wr_data_mix_bus;
wire  [CAS_DATA_WIDTH_A*ADDR_LOOP_NUM_A-1:0]  a_rd_data_bus    ;
wire  [ADDR_WIDTH_A-1:0]                      a_addr_bus       ;
reg   [DATA_LOOP_NUM*14-1:0]                  drm_a_addr       ;
reg                                           a_cs_bit0        ;
reg                                           a_cs_bit1        ;
reg   [ADDR_LOOP_NUM_A-1:0]                   a_cs_bit2_bus    ;
reg                                           a_cs_bit0_ff     ;
reg                                           a_cs_bit1_ff     ;
reg   [ADDR_LOOP_NUM_A-1:0]                   a_cs_bit2_bus_ff ;
wire                                          a_cs_bit0_m      ;
wire                                          a_cs_bit1_m      ;
wire  [ADDR_LOOP_NUM_A-1:0]                   a_cs_bit2_bus_m  ;
reg   [DATA_LOOP_NUM-1:0 ]                    a_wr_en_bus      ;

reg   [CAS_DATA_WIDTH_A-1:0]                  a_rd_mix_data    ;
reg   [CAS_DATA_WIDTH_A-1:0]                  a_rd_full_data   ;

wire  [CAS_DATA_WIDTH_B-1:0]                  b_wr_data_bus    ;
reg   [CAS_DATA_WIDTH_B-1:0]                  b_wr_data_mix_bus;
wire  [CAS_DATA_WIDTH_B*ADDR_LOOP_NUM_B-1:0]  b_rd_data_bus    ;
wire  [ADDR_WIDTH_B-1:0]                      b_addr_bus       ;
reg   [DATA_LOOP_NUM*14-1:0]                  drm_b_addr       ;
reg                                           b_cs_bit0        ;
reg                                           b_cs_bit1        ;
reg   [ADDR_LOOP_NUM_B-1:0]                   b_cs_bit2_bus    ;
reg                                           b_cs_bit0_ff     ;
reg                                           b_cs_bit1_ff     ;
reg   [ADDR_LOOP_NUM_B-1:0]                   b_cs_bit2_bus_ff ;
wire                                          b_cs_bit0_m      ;
wire                                          b_cs_bit1_m      ;
wire  [ADDR_LOOP_NUM_B-1:0]                   b_cs_bit2_bus_m  ;
reg   [DATA_LOOP_NUM-1:0]                     b_wr_en_bus      ;

reg   [CAS_DATA_WIDTH_B-1:0]                  b_rd_mix_data    ;
reg   [CAS_DATA_WIDTH_B-1:0]                  b_rd_full_data   ;

  //byte enable bus 
wire  [CAS_DATA_WIDTH_A/A_WR_BYTE_WIDTH-1 : 0]  a_wr_byte_en_bus    ;
reg   [CAS_DATA_WIDTH_A/A_WR_BYTE_WIDTH-1 : 0]  a_wr_byte_en_mix_bus;
wire  [CAS_DATA_WIDTH_B/B_WR_BYTE_WIDTH-1 : 0]  b_wr_byte_en_bus    ;
reg   [CAS_DATA_WIDTH_B/B_WR_BYTE_WIDTH-1 : 0]  b_wr_byte_en_mix_bus;

assign  a_wr_data_bus[CAS_DATA_WIDTH_A-1:0] = {{(CAS_DATA_WIDTH_A-c_A_DATA_WIDTH){1'b0}},a_wr_data[c_A_DATA_WIDTH-1:0]};

assign  a_addr_bus[ADDR_WIDTH_A-1:0] = {{(ADDR_WIDTH_A-c_A_ADDR_WIDTH){1'b0}},a_addr[c_A_ADDR_WIDTH-1:0]};

assign  b_wr_data_bus[CAS_DATA_WIDTH_B-1:0] = {{(CAS_DATA_WIDTH_B-c_B_DATA_WIDTH){1'b0}},b_wr_data[c_B_DATA_WIDTH-1:0]};

assign  b_addr_bus[ADDR_WIDTH_B-1:0] = {{(ADDR_WIDTH_B-c_B_ADDR_WIDTH){1'b0}},b_addr[c_B_ADDR_WIDTH-1:0]};

  //byte_en_bus 
assign  a_wr_byte_en_bus = (c_WR_BYTE_EN == 0) ? -1 : {{(CAS_DATA_WIDTH_A/A_WR_BYTE_WIDTH-c_A_DATA_WIDTH/A_WR_BYTE_WIDTH){1'b0}},a_wr_byte_en[c_A_BE_WIDTH-1:0]};
assign  b_wr_byte_en_bus = (c_WR_BYTE_EN == 0) ? -1 : {{(CAS_DATA_WIDTH_B/B_WR_BYTE_WIDTH-c_B_DATA_WIDTH/B_WR_BYTE_WIDTH){1'b0}},b_wr_byte_en[c_B_BE_WIDTH-1:0]};

//drm_a_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
//generate drm_a_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
integer gen_drm_a;

always@(*) begin
   for(gen_drm_a=0;gen_drm_a < DATA_LOOP_NUM;gen_drm_a = gen_drm_a +1 ) begin
      case(DRM_DATA_WIDTH_A)
         1      : drm_a_addr[gen_drm_a*14 +: 14]  =  a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0];
         2      : drm_a_addr[gen_drm_a*14 +: 14]  = {a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],1'b0};
         4      : drm_a_addr[gen_drm_a*14 +: 14]  = {a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],2'b00};
         8,9    : drm_a_addr[gen_drm_a*14 +: 14]  = {a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],3'b000};
         16,18  : drm_a_addr[gen_drm_a*14 +: 14]  = {a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],2'b00,a_wr_byte_en_mix_bus[gen_drm_a*2 +:2]};
         default: drm_a_addr[gen_drm_a*14 +: 14]  = 14'b0;
      endcase
   end

end
//****************************************************************************************************************************************
//generate wr_data_mix_bus  and wr_byte_en_mix_bus
integer  gen_i_ad,gen_j_ad;

always@(*) begin 
 //generate a_wr_data_mix_bus 
   if((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM > 1)) begin
      for ( gen_i_ad=0;gen_i_ad<DATA_LOOP_NUM;gen_i_ad=gen_i_ad+1 )
         for( gen_j_ad=0;gen_j_ad<WIDTH_RATIO;gen_j_ad=gen_j_ad+1 )
            a_wr_data_mix_bus[gen_i_ad*DRM_DATA_WIDTH_A+gen_j_ad*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B] = a_wr_data_bus[(gen_i_ad + gen_j_ad*DATA_LOOP_NUM)*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
   end
   else begin
      a_wr_data_mix_bus = a_wr_data_bus;
   end
   //generate wr byte enable mix bus 
   if((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM > 1) && (c_WR_BYTE_EN == 1)) begin
      for (gen_i_ad=0;gen_i_ad < DATA_LOOP_NUM;gen_i_ad =gen_i_ad+1)
         for(gen_j_ad=0;gen_j_ad < WIDTH_RATIO ; gen_j_ad = gen_j_ad+1 )
            a_wr_byte_en_mix_bus[gen_i_ad*(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH)+gen_j_ad*(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH)] = a_wr_byte_en_bus[(gen_i_ad + gen_j_ad*DATA_LOOP_NUM)*(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH)];
   end
   else begin
      a_wr_byte_en_mix_bus = a_wr_byte_en_bus;
   end 

   //generate a_wr_en_bus
   if((c_WR_BYTE_EN == 1) && ((DRM_DATA_WIDTH_A == 8) || (DRM_DATA_WIDTH_A == 9))) begin
      a_wr_en_bus = a_wr_byte_en_mix_bus & {CAS_DATA_WIDTH_A/A_WR_BYTE_WIDTH{a_wr_en}};
   end
   else begin
      for (gen_i_ad=0;gen_i_ad < DATA_LOOP_NUM;gen_i_ad =gen_i_ad+1)
         a_wr_en_bus[gen_i_ad] = a_wr_en;
   end 

end
//*********************************************************************************************************************************************************
//drm_b_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
integer gen_drm_b;

always@(*) begin 
   for(gen_drm_b=0;gen_drm_b < DATA_LOOP_NUM;gen_drm_b = gen_drm_b+1) begin 
      case(DRM_DATA_WIDTH_B)
         1      : drm_b_addr[gen_drm_b*14 +: 14] = b_addr_bus[(ADDR_WIDTH_B-CS_ADDR_WIDTH_B-1):0];
         2      : drm_b_addr[gen_drm_b*14 +: 14] = {b_addr_bus[(ADDR_WIDTH_B-CS_ADDR_WIDTH_B-1):0],1'b0};
         4      : drm_b_addr[gen_drm_b*14 +: 14] = {b_addr_bus[(ADDR_WIDTH_B-CS_ADDR_WIDTH_B-1):0],2'b00};
         8,9    : drm_b_addr[gen_drm_b*14 +: 14] = {b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],3'b000};
         16,18  : drm_b_addr[gen_drm_b*14 +: 14] = {b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],2'b00,b_wr_byte_en_mix_bus[gen_drm_b*2 +: 2]};
         default: drm_b_addr[gen_drm_b*14 +: 14] = 14'b0;
      endcase 
   end 
end
//***********************************************************************************************************************************************************
//generate b_wr_data_mix_bus  and b_wr_byte_en_mix_bus
integer  gen_i_bd,gen_j_bd;

always@(*) begin
   //generate b_wr_data_mix_bus
   if((c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM > 1)) begin
      for (gen_i_bd=0;gen_i_bd < DATA_LOOP_NUM;gen_i_bd =gen_i_bd+1)
         for(gen_j_bd=0;gen_j_bd < WIDTH_RATIO ; gen_j_bd = gen_j_bd+1 )
            b_wr_data_mix_bus[gen_i_bd*DRM_DATA_WIDTH_B+gen_j_bd*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A] = b_wr_data_bus[(gen_i_bd + gen_j_bd*DATA_LOOP_NUM)*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
   end
   else begin
      b_wr_data_mix_bus = b_wr_data_bus;
   end

   //generate b wr byte enable mix bus 
   if((c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM > 1) && (c_WR_BYTE_EN ==1)) begin
      for (gen_i_bd=0;gen_i_bd < DATA_LOOP_NUM;gen_i_bd =gen_i_bd+1)
         for(gen_j_bd=0;gen_j_bd < WIDTH_RATIO ; gen_j_bd = gen_j_bd+1 )
            b_wr_byte_en_mix_bus[gen_i_bd*(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH)+gen_j_bd*(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH)] = b_wr_byte_en_bus[(gen_i_bd + gen_j_bd*DATA_LOOP_NUM)*(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH)];

   end
   else begin
      b_wr_byte_en_mix_bus = b_wr_byte_en_bus;
   end

   //generate b_wr_en_bus
   if((c_WR_BYTE_EN == 1) && ((DRM_DATA_WIDTH_B == 8) || (DRM_DATA_WIDTH_B == 9))) begin
      b_wr_en_bus = b_wr_byte_en_mix_bus & {CAS_DATA_WIDTH_B/B_WR_BYTE_WIDTH{b_wr_en}};
   end
   else begin
      for (gen_i_bd=0;gen_i_bd < DATA_LOOP_NUM;gen_i_bd =gen_i_bd+1)
         b_wr_en_bus[gen_i_bd] = b_wr_en;
   end 

end

localparam  CS_ADDR_A_4_LSB = (CS_ADDR_WIDTH_A >= 4) ? (ADDR_WIDTH_A-1-CS_ADDR_WIDTH_A+3) : (ADDR_WIDTH_A-2);
localparam  CS_ADDR_B_4_LSB = (CS_ADDR_WIDTH_B >= 4) ? (ADDR_WIDTH_B-1-CS_ADDR_WIDTH_B+3) : (ADDR_WIDTH_B-2);

//generate CSA and CSB
integer  gen_cs;

always@(*) begin
   if(CS_ADDR_WIDTH_A == 0) begin
      a_cs_bit0 = 0;
      a_cs_bit1 = 0;
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
         a_cs_bit2_bus[gen_cs] = 0;
   end 
   else if(CS_ADDR_WIDTH_A == 1) begin
      a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-CS_ADDR_WIDTH_A];
      a_cs_bit1 = 0;
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
         a_cs_bit2_bus[gen_cs] = 0;
   end 
   else if(CS_ADDR_WIDTH_A == 2) begin
      a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-2];
      a_cs_bit1 = a_addr_bus[ADDR_WIDTH_A-1];
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
         a_cs_bit2_bus[gen_cs] = 0;
   end 
   else if(CS_ADDR_WIDTH_A == 3) begin
      a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-3];
      a_cs_bit1 = a_addr_bus[ADDR_WIDTH_A-2];
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
         a_cs_bit2_bus[gen_cs] = a_addr_bus[ADDR_WIDTH_A-1];
   end 
   else if(CS_ADDR_WIDTH_A >= 4) begin
      a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-CS_ADDR_WIDTH_A];
      a_cs_bit1 = a_addr_bus[ADDR_WIDTH_A-CS_ADDR_WIDTH_A+1];
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
         a_cs_bit2_bus[gen_cs] = (a_addr_bus[(ADDR_WIDTH_A-1):CS_ADDR_A_4_LSB] == (gen_cs/4)) ? 0 : 1;
   end

   //generate CSB
   if(CS_ADDR_WIDTH_B == 0) begin
      b_cs_bit0 = 0;
      b_cs_bit1 = 0;
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
         b_cs_bit2_bus[gen_cs] = 0;
   end 
   else if(CS_ADDR_WIDTH_B == 1) begin
      b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-CS_ADDR_WIDTH_B];
      b_cs_bit1 = 0;
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
         b_cs_bit2_bus[gen_cs] = 0;
   end 
   else if(CS_ADDR_WIDTH_B == 2) begin
      b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-2];
      b_cs_bit1 = b_addr_bus[ADDR_WIDTH_B-1];
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
         b_cs_bit2_bus[gen_cs] = 0;
   end 
   else if(CS_ADDR_WIDTH_B == 3) begin
      b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-3];
      b_cs_bit1 = b_addr_bus[ADDR_WIDTH_B-2];
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
         b_cs_bit2_bus[gen_cs] = b_addr_bus[ADDR_WIDTH_B-1];
   end 
   else if(CS_ADDR_WIDTH_B >= 4) begin
      b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-CS_ADDR_WIDTH_B];
      b_cs_bit1 = b_addr_bus[ADDR_WIDTH_B-CS_ADDR_WIDTH_B+1];
      for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
         b_cs_bit2_bus[gen_cs] = (b_addr_bus[(ADDR_WIDTH_B-1):CS_ADDR_B_4_LSB] == (gen_cs/4) ) ? 0 : 1;
   end 
end

always @(posedge a_clk or posedge a_rst)
begin
    if (a_rst) begin
        a_cs_bit0_ff     <= 0;
        a_cs_bit1_ff     <= 0;
        a_cs_bit2_bus_ff <= 0;
    end
    else if(~a_addr_strobe) begin
        a_cs_bit0_ff     <= a_cs_bit0;
        a_cs_bit1_ff     <= a_cs_bit1;
        a_cs_bit2_bus_ff <= a_cs_bit2_bus;
    end
end

assign a_cs_bit0_m     = (c_SIM_DEVICE == "PGL22G") ? (a_addr_strobe ? a_cs_bit0_ff     : a_cs_bit0    ) : a_cs_bit0;
assign a_cs_bit1_m     = (c_SIM_DEVICE == "PGL22G") ? (a_addr_strobe ? a_cs_bit1_ff     : a_cs_bit1    ) : a_cs_bit1;
assign a_cs_bit2_bus_m = (c_SIM_DEVICE == "PGL22G") ? (a_addr_strobe ? a_cs_bit2_bus_ff : a_cs_bit2_bus) : a_cs_bit2_bus;

always @(posedge b_clk or posedge b_rst)
begin
    if (b_rst) begin
        b_cs_bit0_ff     <= 0;
        b_cs_bit1_ff     <= 0;
        b_cs_bit2_bus_ff <= 0;
    end
    else if(~b_addr_strobe) begin
        b_cs_bit0_ff     <= b_cs_bit0;
        b_cs_bit1_ff     <= b_cs_bit1;
        b_cs_bit2_bus_ff <= b_cs_bit2_bus;
    end
end

assign b_cs_bit0_m     = (c_SIM_DEVICE == "PGL22G") ? (b_addr_strobe ? b_cs_bit0_ff     : b_cs_bit0    ) : b_cs_bit0;
assign b_cs_bit1_m     = (c_SIM_DEVICE == "PGL22G") ? (b_addr_strobe ? b_cs_bit1_ff     : b_cs_bit1    ) : b_cs_bit1;
assign b_cs_bit2_bus_m = (c_SIM_DEVICE == "PGL22G") ? (b_addr_strobe ? b_cs_bit2_bus_ff : b_cs_bit2_bus) : b_cs_bit2_bus;

wire [18*DATA_LOOP_NUM*ADDR_LOOP_NUM_A-1:0]  QA_bus;
wire [18*DATA_LOOP_NUM*ADDR_LOOP_NUM_B-1:0]  QB_bus;
wire [18*DATA_LOOP_NUM-1:0]                  DA_bus;
wire [18*DATA_LOOP_NUM-1:0]                  DB_bus;

//generate constructs: ADDR_LOOP to cascade request address  and  DATA LOOP to cascade request data 
genvar gen_i,gen_j;
generate 
  for(gen_j=0;gen_j<ADDR_LOOP_NUM_A;gen_j=gen_j+1) begin:ADDR_LOOP 
     for(gen_i=0;gen_i<DATA_LOOP_NUM;gen_i=gen_i+1) begin:DATA_LOOP
        localparam csa_mask = gen_j%MASK_NUM_A;
        localparam csb_mask = gen_j%MASK_NUM_B; 
     //write data 
        if(DRM_DATA_WIDTH_A == 16 ) begin:QA_MAP
           assign  a_rd_data_bus[(gen_i*DRM_DATA_WIDTH_A+gen_j*CAS_DATA_WIDTH_A) +:DRM_DATA_WIDTH_A] = {QA_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM+9) +:8],QA_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM) +:8]};
           assign  {DA_bus[(gen_i*18+9) +:8 ],DA_bus[gen_i*18 +:8]} = a_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
        end
        else begin:QA_MAP
           assign  a_rd_data_bus[(gen_i*DRM_DATA_WIDTH_A+gen_j*CAS_DATA_WIDTH_A) +:DRM_DATA_WIDTH_A] = QA_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM) +:DRM_DATA_WIDTH_A];
           assign  DA_bus[gen_i*18 +:DRM_DATA_WIDTH_A] = a_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
        end

        if(DRM_DATA_WIDTH_B == 16 ) begin:QB_MAP
           assign  b_rd_data_bus[(gen_i*DRM_DATA_WIDTH_B+gen_j*CAS_DATA_WIDTH_B) +:DRM_DATA_WIDTH_B] = {QB_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM+9) +:8],QB_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM) +:8]};
           assign  {DB_bus[(gen_i*18+9) +:8],DB_bus[gen_i*18 +:8]} = b_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
        end
        else begin:QB_MAP
           assign  b_rd_data_bus[(gen_i*DRM_DATA_WIDTH_B+gen_j*CAS_DATA_WIDTH_B) +:DRM_DATA_WIDTH_B] = QB_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM) +:DRM_DATA_WIDTH_B];
           assign  DB_bus[gen_i*18 +:DRM_DATA_WIDTH_B] = b_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
        end 

        GTP_DRM18K # (

                 .GRS_EN                   ( "FALSE"                  ),
                 .SIM_DEVICE               ( c_SIM_DEVICE             ),
                 .CSA_MASK                 ( csa_mask                 ),
                 .CSB_MASK                 ( csb_mask                 ),  
                 .DATA_WIDTH_A             ( DRM_DATA_WIDTH_A         ),    // 1 2 4 8 16 9 18 
                 .DATA_WIDTH_B             ( DRM_DATA_WIDTH_B         ),    // 1 2 4 8 16 9 18                     
                 .WRITE_MODE_A             ( c_A_WRITE_MODE           ),
                 .WRITE_MODE_B             ( c_B_WRITE_MODE           ),   
                 .DOA_REG                  ( c_A_OUTPUT_REG           ),
                 .DOB_REG                  ( c_B_OUTPUT_REG           ),
                 .DOA_REG_CLKINV           ( c_A_CLK_OR_POL_INV       ),
                 .DOB_REG_CLKINV           ( c_B_CLK_OR_POL_INV       ),
                 .RST_TYPE                 ( c_RST_TYPE               ),    // ASYNC_RESET_SYNC_RELEASE SYNC_RESET
                 .RAM_MODE                 ( "TRUE_DUAL_PORT"         ),    // TRUE_DUAL_PORT                   
                 .INIT_FILE                ( c_INIT_FILE              ),                 
                 .BLOCK_X                  ( gen_i                    ),
                 .BLOCK_Y                  ( gen_j                    ),
                 .RAM_ADDR_WIDTH           ( ADDR_WIDTH_A             ),
                 .RAM_DATA_WIDTH           ( CAS_DATA_WIDTH_A         ),
                 .INIT_FORMAT              ( c_INIT_FORMAT            )    //binary or hex       
        ) U_GTP_DRM18K (
                .DOA(QA_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM) +:18]),
                .ADDRA(drm_a_addr[gen_i*14 +:14]),            //wr_addr[13:0]
                .ADDRA_HOLD(a_addr_strobe),
                .DIA(DA_bus[gen_i*18 +:18]),
                .CSA({a_cs_bit2_bus_m[gen_j],a_cs_bit1_m,a_cs_bit0_m}),
                .WEA(a_wr_en_bus[gen_i]),
                .CLKA(a_clk),
                .CEA(a_clk_en),
                .ORCEA(a_rd_oce),
                .RSTA(a_rst),

                .DOB(QB_bus[(gen_i*18+gen_j*18*DATA_LOOP_NUM) +:18]),
                .ADDRB(drm_b_addr[gen_i*14 +:14]),             //rd_addr[13:0]
                .ADDRB_HOLD(b_addr_strobe),
                .DIB(DB_bus[gen_i*18 +:18]),
                .CSB({b_cs_bit2_bus_m[gen_j],b_cs_bit1_m,b_cs_bit0_m}),
                .WEB(b_wr_en_bus[gen_i]),
                .CLKB(b_clk),
                .CEB(b_clk_en),
                .ORCEB(b_rd_oce),
                .RSTB(b_rst)
       );
     end 
  end 
endgenerate

//**********************************************************************************************************************************************************************************
//generate a_rd_data
localparam   A_ADDR_SEL_LSB = (CS_ADDR_WIDTH_A > 0) ? (ADDR_WIDTH_A - CS_ADDR_WIDTH_A) : (ADDR_WIDTH_A - 1);
//rd_data: extra mux combination  logic
wire [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_sel;
reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_ce;
reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_ce_ff;
wire [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_ce_mux;
reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_oce;
reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_invt;

reg     a_wr_en_ff;

//CE
always @(posedge a_clk or posedge a_rst)
begin
    if (a_rst)
        a_addr_bus_rd_ce <= 0;
    else if (~a_addr_strobe & a_clk_en)
        a_addr_bus_rd_ce <= a_addr_bus[(ADDR_WIDTH_A-1): A_ADDR_SEL_LSB];
end

always @(posedge a_clk or posedge a_rst)
begin
    if (a_rst)
        a_wr_en_ff <= 1'b0;
    else if (a_clk_en)
        a_wr_en_ff <= a_wr_en;
end

always @(posedge a_clk or posedge a_rst)
begin
    if (a_rst)
        a_addr_bus_rd_ce_ff <= 0;
    else if (~a_wr_en_ff)
        a_addr_bus_rd_ce_ff <= a_addr_bus_rd_ce;
end

assign a_addr_bus_rd_ce_mux = (c_A_WRITE_MODE != "NORMAL_WRITE") ? a_addr_bus_rd_ce : a_wr_en_ff ? a_addr_bus_rd_ce_ff : a_addr_bus_rd_ce;

//OCE
always @(posedge a_clk or posedge a_rst)
begin
    if (a_rst)
        a_addr_bus_rd_oce <= 0;
    else if (a_rd_oce)
        a_addr_bus_rd_oce <= a_addr_bus_rd_ce_mux;
end

//INVT
always @(negedge a_clk or posedge a_rst)
begin
    if (a_rst)
        a_addr_bus_rd_invt <= 0;
    else if (a_rd_oce)
        a_addr_bus_rd_invt <= a_addr_bus_rd_ce_mux;
end

assign  a_addr_bus_rd_sel = (c_A_CLK_OR_POL_INV == 1) ? a_addr_bus_rd_invt : (c_A_OUTPUT_REG == 1) ? a_addr_bus_rd_oce : a_addr_bus_rd_ce_mux;

//****************************************************************************************************************************************
//generate a_rd_data_bus from rd_data_mix_bus 
integer rd_a_n;
always@(*) begin
   a_rd_mix_data = 'b0;
   if(ADDR_LOOP_NUM_A>1) begin 
      for(rd_a_n=0;rd_a_n<ADDR_LOOP_NUM_A;rd_a_n=rd_a_n+1) begin
         if(a_addr_bus_rd_sel== rd_a_n)
               a_rd_mix_data = a_rd_data_bus[rd_a_n*CAS_DATA_WIDTH_A +:CAS_DATA_WIDTH_A];
      end
   end
   else begin
      a_rd_mix_data = a_rd_data_bus;
   end 
end

integer gen_i_rad,gen_j_rad;
always@(*) begin
   if((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM>1)) begin
      for (gen_i_rad=0;gen_i_rad < WIDTH_RATIO;gen_i_rad = gen_i_rad + 1)
         for(gen_j_rad=0;gen_j_rad < DATA_LOOP_NUM  ;gen_j_rad = gen_j_rad+1)
            a_rd_full_data[gen_i_rad*(CAS_DATA_WIDTH_A/WIDTH_RATIO)+gen_j_rad*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B] = a_rd_mix_data[(gen_i_rad + gen_j_rad*WIDTH_RATIO)*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
   end
   else begin
      a_rd_full_data = a_rd_mix_data;
   end
end

assign  a_rd_data = a_rd_full_data[c_A_DATA_WIDTH-1:0];

//*******************************************************************************************************************************************************************
//generate   b_rd_data
localparam   B_ADDR_SEL_LSB = (CS_ADDR_WIDTH_B > 0) ? (ADDR_WIDTH_B - CS_ADDR_WIDTH_B) : (ADDR_WIDTH_B - 1);

wire [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_sel;
reg  [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_ce;
reg  [CS_ADDR_WIDTH_A-1:0]   b_addr_bus_rd_ce_ff;
wire [CS_ADDR_WIDTH_A-1:0]   b_addr_bus_rd_ce_mux;
reg  [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_oce;
reg  [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_invt;

reg     b_wr_en_ff;

//CE
always @(posedge b_clk or posedge b_rst)
begin
    if (b_rst)
        b_addr_bus_rd_ce <= 0;
    else if (~b_addr_strobe & b_clk_en)
        b_addr_bus_rd_ce <= b_addr_bus[(ADDR_WIDTH_B-1): B_ADDR_SEL_LSB];
end

always @(posedge b_clk or posedge b_rst)
begin
    if (b_rst)
        b_wr_en_ff <= 1'b0;
    else if (b_clk_en)
        b_wr_en_ff <= b_wr_en;
end

always @(posedge b_clk or posedge b_rst)
begin
    if (b_rst)
        b_addr_bus_rd_ce_ff <= 0;
    else if (~b_wr_en_ff)
        b_addr_bus_rd_ce_ff <= b_addr_bus_rd_ce;
end

assign b_addr_bus_rd_ce_mux = (c_B_WRITE_MODE != "NORMAL_WRITE") ? b_addr_bus_rd_ce : b_wr_en_ff ? b_addr_bus_rd_ce_ff : b_addr_bus_rd_ce;

//OCE
always @(posedge b_clk or posedge b_rst)
begin
    if (b_rst)
        b_addr_bus_rd_oce <= 0;
    else if (b_rd_oce)
        b_addr_bus_rd_oce <= b_addr_bus_rd_ce_mux;
end

//INVT
always @(negedge b_clk or posedge b_rst)
begin
    if (b_rst)
        b_addr_bus_rd_invt <= 0;
    else if (b_rd_oce)
        b_addr_bus_rd_invt <= b_addr_bus_rd_ce_mux;
end

assign  b_addr_bus_rd_sel = (c_B_CLK_OR_POL_INV == 1) ? b_addr_bus_rd_invt : (c_B_OUTPUT_REG == 1) ? b_addr_bus_rd_oce : b_addr_bus_rd_ce_mux;

integer rd_b_n;
always@(*) begin
   b_rd_mix_data = 'b0;
   if(ADDR_LOOP_NUM_B > 1) begin
      for(rd_b_n=0;rd_b_n<ADDR_LOOP_NUM_B;rd_b_n=rd_b_n+1) begin
         if(b_addr_bus_rd_sel == rd_b_n)
            b_rd_mix_data = b_rd_data_bus[rd_b_n*CAS_DATA_WIDTH_B +:CAS_DATA_WIDTH_B];
      end
   end
   else begin
      b_rd_mix_data = b_rd_data_bus;
   end
end

integer gen_i_rbd,gen_j_rbd;
always@(*) begin
   if((c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM > 1)) begin
      for (gen_i_rbd=0;gen_i_rbd < WIDTH_RATIO;gen_i_rbd = gen_i_rbd + 1)
         for(gen_j_rbd=0;gen_j_rbd < DATA_LOOP_NUM  ;gen_j_rbd = gen_j_rbd+1)
            b_rd_full_data[gen_i_rbd*(CAS_DATA_WIDTH_B/WIDTH_RATIO)+gen_j_rbd*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A] = b_rd_mix_data[(gen_i_rbd + gen_j_rbd*WIDTH_RATIO)*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
   end
   else begin
      b_rd_full_data = b_rd_mix_data;
   end
end

assign  b_rd_data = b_rd_full_data[c_B_DATA_WIDTH-1 : 0];


endmodule

