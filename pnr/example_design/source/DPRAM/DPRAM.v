
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
// Library:
// Filename:DPRAM.v
//////////////////////////////////////////////////////////////////////////////

module DPRAM
   (
    a_addr        ,
    a_wr_data     ,
    a_rd_data     ,
    a_wr_en       ,
    
    a_rst         ,
    
    a_clk         ,

    b_addr        ,
    b_wr_data     ,
    b_rd_data     ,
    b_wr_en       ,
    
    b_rst         ,
    
    b_clk
   );


localparam A_ADDR_WIDTH = 10 ; // @IPC int 9,20

localparam A_DATA_WIDTH = 10 ; // @IPC int 1,1152

localparam B_ADDR_WIDTH = 10 ; // @IPC int 9,20

localparam B_DATA_WIDTH = 10 ; // @IPC int 1,1152

localparam A_OUTPUT_REG = 0 ; // @IPC bool

localparam A_RD_OCE_EN = 0 ; // @IPC bool

localparam B_OUTPUT_REG = 0 ; // @IPC bool

localparam B_RD_OCE_EN = 0 ; // @IPC bool

localparam A_CLK_OR_POL_INV = 0 ; // @IPC bool

localparam B_CLK_OR_POL_INV = 0 ; // @IPC bool

localparam POWER_OPT = 0 ; // @IPC bool

localparam INIT_FILE = "NONE" ; // @IPC string

localparam INIT_FORMAT = "BIN" ; // @IPC enum BIN,HEX

localparam WR_BYTE_EN = 0 ; // @IPC bool

localparam A_BE_WIDTH = 1 ; // @IPC int 2,128

localparam B_BE_WIDTH = 1 ; // @IPC int 2,128

localparam A_WRITE_MODE = "NORMAL_WRITE"; // @IPC enum NORMAL_WRITE,TRANSPARENT_WRITE,READ_BEFORE_WRITE

localparam B_WRITE_MODE = "NORMAL_WRITE"; // @IPC enum NORMAL_WRITE,TRANSPARENT_WRITE,READ_BEFORE_WRITE

localparam RESET_TYPE = "ASYNC" ; // @IPC enum Sync_Internally,SYNC,ASYNC

localparam BYTE_SIZE = 8 ; // @IPC enum 8,9

localparam INIT_EN = 0 ; // @IPC bool

localparam SAMEWIDTH_EN = 1 ; // @IPC bool

localparam A_CLK_EN = 0 ; // @IPC bool

localparam B_CLK_EN = 0 ; // @IPC bool

localparam A_ADDR_STROBE_EN = 0 ; // @IPC bool

localparam B_ADDR_STROBE_EN = 0 ; // @IPC bool

localparam  RESET_TYPE_SEL              = (RESET_TYPE == "ASYNC") ? "ASYNC_RESET" :
                                          (RESET_TYPE == "SYNC")  ? "SYNC_RESET"  : "ASYNC_RESET_SYNC_RELEASE";
localparam  DEVICE_NAME                 = "PGL50H";

localparam  A_DATA_WIDTH_WRAP           = ((DEVICE_NAME == "PGT30G") && (A_DATA_WIDTH <= 9)) ? 10 : A_DATA_WIDTH;
localparam  B_DATA_WIDTH_WRAP           = ((DEVICE_NAME == "PGT30G") && (B_DATA_WIDTH <= 9)) ? 10 : B_DATA_WIDTH;
localparam  SIM_DEVICE                  = ((DEVICE_NAME == "PGL22G") || (DEVICE_NAME == "PGL22GS")) ? "PGL22G" : "LOGOS";


input [A_ADDR_WIDTH-1 : 0]   a_addr        ;
input [A_DATA_WIDTH-1 : 0]   a_wr_data     ;
output[A_DATA_WIDTH-1 : 0]   a_rd_data     ;
input                        a_wr_en       ;
input                        a_clk         ;

input                        a_rst         ;

input [B_ADDR_WIDTH-1 : 0]   b_addr        ;
input [B_DATA_WIDTH-1 : 0]   b_wr_data     ;
output[B_DATA_WIDTH-1 : 0]   b_rd_data     ;
input                        b_wr_en       ;
input                        b_clk         ;

input                        b_rst         ;


wire [A_ADDR_WIDTH-1 : 0]    a_addr        ;
wire [A_DATA_WIDTH-1 : 0]    a_wr_data     ;
wire [A_DATA_WIDTH-1 : 0]    a_rd_data     ;
wire                         a_wr_en       ;
wire                         a_clk         ;
wire                         a_clk_en      ;
wire                         a_rst         ;
wire [A_BE_WIDTH-1 : 0]      a_wr_byte_en  ;
wire                         a_rd_oce      ;
wire                         a_addr_strobe ;

wire [B_ADDR_WIDTH-1 : 0]    b_addr        ;
wire [B_DATA_WIDTH-1 : 0]    b_wr_data     ;
wire [B_DATA_WIDTH-1 : 0]    b_rd_data     ;
wire                         b_wr_en       ;
wire                         b_clk         ;
wire                         b_clk_en      ;
wire                         b_rst         ;
wire [B_BE_WIDTH-1:0]        b_wr_byte_en  ;
wire                         b_rd_oce      ;
wire                         b_addr_strobe ;

wire [A_BE_WIDTH-1:0]        a_wr_byte_en_mux  ;
wire                         a_rd_oce_mux      ;
wire [B_BE_WIDTH-1:0]        b_wr_byte_en_mux  ;
wire                         b_rd_oce_mux      ;
wire                         a_clk_en_mux      ;
wire                         b_clk_en_mux      ;
wire                         a_addr_strobe_mux ;
wire                         b_addr_strobe_mux ;

wire [A_DATA_WIDTH_WRAP-1 : 0] a_wr_data_wrap;
wire [A_DATA_WIDTH_WRAP-1 : 0] a_rd_data_wrap;
wire [B_DATA_WIDTH_WRAP-1 : 0] b_wr_data_wrap;
wire [B_DATA_WIDTH_WRAP-1 : 0] b_rd_data_wrap;


assign a_wr_byte_en_mux  = (WR_BYTE_EN       == 1) ? a_wr_byte_en  : -1 ;
assign a_rd_oce_mux      = (A_RD_OCE_EN      == 1) ? a_rd_oce      :
                           (A_OUTPUT_REG     == 1) ? 1'b1 : 1'b0 ;
assign b_wr_byte_en_mux  = (WR_BYTE_EN       == 1) ? b_wr_byte_en  : -1 ;
assign b_rd_oce_mux      = (B_RD_OCE_EN      == 1) ? b_rd_oce      :
                           (B_OUTPUT_REG     == 1) ? 1'b1 : 1'b0 ;
assign a_clk_en_mux      = (A_CLK_EN         == 1) ? a_clk_en      : 1'b1 ;
assign b_clk_en_mux      = (B_CLK_EN         == 1) ? b_clk_en      : 1'b1 ;
assign a_addr_strobe_mux = (A_ADDR_STROBE_EN == 1) ? a_addr_strobe : 1'b0 ;
assign b_addr_strobe_mux = (B_ADDR_STROBE_EN == 1) ? b_addr_strobe : 1'b0 ;


assign a_wr_data_wrap    = ((DEVICE_NAME == "PGT30G") && (A_DATA_WIDTH <= 9)) ? {{(A_DATA_WIDTH_WRAP - A_DATA_WIDTH){1'b0}},a_wr_data} : a_wr_data;
assign a_rd_data         = ((DEVICE_NAME == "PGT30G") && (A_DATA_WIDTH <= 9)) ? a_rd_data_wrap[A_DATA_WIDTH-1 : 0] : a_rd_data_wrap;
assign b_wr_data_wrap    = ((DEVICE_NAME == "PGT30G") && (B_DATA_WIDTH <= 9)) ? {{(B_DATA_WIDTH_WRAP - B_DATA_WIDTH){1'b0}},b_wr_data} : b_wr_data;
assign b_rd_data         = ((DEVICE_NAME == "PGT30G") && (B_DATA_WIDTH <= 9)) ? b_rd_data_wrap[B_DATA_WIDTH-1 : 0] : b_rd_data_wrap;


//pg_flex_sdpram IP instance
ipml_dpram_v1_6_DPRAM
    #(
    .c_SIM_DEVICE              (SIM_DEVICE                   ),
    .c_A_ADDR_WIDTH            (A_ADDR_WIDTH                 ),  //write address width  legal value:9~20 
    .c_A_DATA_WIDTH            (A_DATA_WIDTH_WRAP            ),  //write data width     1)WR_BYTE_EN =0 legal value:1~1152  2)WR_BYTE_EN=1  legal value:2^N or 9*2^N
    .c_B_ADDR_WIDTH            (B_ADDR_WIDTH                 ),  //read address width   legal value:9~20
    .c_B_DATA_WIDTH            (B_DATA_WIDTH_WRAP            ),  //read data width      1)WR_BYTE_EN =0 legal value:1~1152  2)WR_BYTE_EN=1  legal value:2^N or 9*2^N
    .c_A_OUTPUT_REG            (A_OUTPUT_REG                 ),  //port A output register      legal value: 0 or 1 
    .c_B_OUTPUT_REG            (B_OUTPUT_REG                 ),  //PORT B output register      legal value: 1 or 0
    .c_A_RD_OCE_EN             (A_RD_OCE_EN                  ),  //port A rd_oce enable
    .c_B_RD_OCE_EN             (B_RD_OCE_EN                  ),  //port B rd_oce enable
    .c_A_ADDR_STROBE_EN        (A_ADDR_STROBE_EN             ),
    .c_B_ADDR_STROBE_EN        (B_ADDR_STROBE_EN             ),
    .c_A_CLK_EN                (A_CLK_EN                     ),
    .c_B_CLK_EN                (B_CLK_EN                     ),
    .c_RESET_TYPE              (RESET_TYPE_SEL               ),  //reset type legal valve "ASYNC_RESET_SYNC_RELEASE" "SYNC_RESET" "ASYNC_RESET"
    .c_A_CLK_OR_POL_INV        (A_CLK_OR_POL_INV             ),  //clk polarity invert for output register    legal value: 1 or 0
    .c_B_CLK_OR_POL_INV        (B_CLK_OR_POL_INV             ),  //clk polarity invert for output register    legal value: 1 or 0
    .c_POWER_OPT               (POWER_OPT                    ),  //0 :normal mode  1:low power mode legal value: 1 or 0
    .c_INIT_FILE               ("NONE"                       ),  //legal value:"NONE" or "initial file name"
    .c_INIT_FORMAT             (INIT_FORMAT                  ),  //legal value "bin" or "hex"
    .c_WR_BYTE_EN              (WR_BYTE_EN                   ),  //legal value: 0 or 1
    .c_A_BE_WIDTH              (A_BE_WIDTH                   ),  //PORT A byte write width  legal value: 1~128
    .c_B_BE_WIDTH              (B_BE_WIDTH                   ),  //PORT B byte write width  legal value: 1~128
    .c_A_WRITE_MODE            (A_WRITE_MODE                 ),  //legal value "TRANSPARENT_WRITE" "READ_BEFORE_WRITE"
    .c_B_WRITE_MODE            (B_WRITE_MODE                 )  //legal value "TRANSPARENT_WRITE" "READ_BEFORE_WRITE"
    ) U_ipml_dpram_DPRAM
    (
    .a_addr        ( a_addr             ),
    .a_wr_data     ( a_wr_data_wrap     ),
    .a_rd_data     ( a_rd_data_wrap     ),
    .a_wr_en       ( a_wr_en            ),
    .a_clk         ( a_clk              ),
    .a_clk_en      ( a_clk_en_mux       ),
    .a_rst         ( a_rst              ),
    .a_wr_byte_en  ( a_wr_byte_en_mux   ),
    .a_rd_oce      ( a_rd_oce_mux       ),
    .a_addr_strobe ( a_addr_strobe_mux  ),
    .b_addr        ( b_addr             ),
    .b_wr_data     ( b_wr_data_wrap     ),
    .b_rd_data     ( b_rd_data_wrap     ),
    .b_wr_en       ( b_wr_en            ),
    .b_clk         ( b_clk              ),
    .b_clk_en      ( b_clk_en_mux       ),
    .b_rst         ( b_rst              ),
    .b_wr_byte_en  ( b_wr_byte_en_mux   ),
    .b_rd_oce      ( b_rd_oce_mux       ),
    .b_addr_strobe ( b_addr_strobe_mux  )
    );

endmodule
