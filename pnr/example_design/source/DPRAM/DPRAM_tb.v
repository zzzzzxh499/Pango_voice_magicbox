
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
// Filename:TB DPRAM_tb.v 
//////////////////////////////////////////////////////////////////////////////
`timescale   1ns / 1ps

module  DPRAM_tb;
  localparam  T_CLK_PERIOD       = 10 ;       //clock a half perid
  localparam  T_RST_TIME         = 200 ;       //reset time 


localparam A_ADDR_WIDTH = 10 ; // @IPC int 9,20

localparam A_DATA_WIDTH = 18 ; // @IPC int 1,1152

localparam B_ADDR_WIDTH = 10 ; // @IPC int 9,20

localparam B_DATA_WIDTH = 18 ; // @IPC int 1,1152

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

localparam A_WRITE_MODE = "NORMAL_WRITE" ; // @IPC enum NORMAL_WRITE,TRANSPARENT_WRITE,READ_BEFORE_WRITE

localparam B_WRITE_MODE = "NORMAL_WRITE" ; // @IPC enum NORMAL_WRITE,TRANSPARENT_WRITE,READ_BEFORE_WRITE

localparam RESET_TYPE = "ASYNC" ; // @IPC enum Sync_Internally,SYNC,ASYNC

localparam BYTE_SIZE = 8 ; // @IPC enum 8,9

localparam INIT_EN = 0 ; // @IPC bool

localparam SAMEWIDTH_EN = 1 ; // @IPC bool

localparam A_CLK_EN = 0 ; // @IPC bool

localparam B_CLK_EN = 0 ; // @IPC bool

localparam A_ADDR_STROBE_EN = 0 ; // @IPC bool

localparam B_ADDR_STROBE_EN = 0 ; // @IPC bool

localparam  RESET_TYPE_SEL              = (RESET_TYPE == "ASYNC") ? "ASYNC_RESET" :
                                          (RESET_TYPE == "SYNC") ? "SYNC_RESET": "ASYNC_RESET_SYNC_RELEASE" ;
localparam  DEVICE_NAME                 = "PGL50H";

localparam  A_DATA_WIDTH_WRAP           = ((DEVICE_NAME == "PGT30G") && (A_DATA_WIDTH <= 9)) ? 10 : A_DATA_WIDTH;
localparam  B_DATA_WIDTH_WRAP           = ((DEVICE_NAME == "PGT30G") && (B_DATA_WIDTH <= 9)) ? 10 : B_DATA_WIDTH;
// variable declaration 
reg                           a_clk              ;
reg                           b_clk              ;
reg   [A_ADDR_WIDTH   : 0]    tb_a_addr          ;
wire  [A_DATA_WIDTH-1 : 0]    tb_a_wrdata        ;
wire  [A_DATA_WIDTH-1 : 0]    tb_a_rddata        ;
reg                           tb_a_wr_en         ;
reg                           tb_a_clk_en        ;
reg                           tb_a_rst           ;
reg   [A_BE_WIDTH-1   : 0]    tb_a_wr_byte_en    ;
reg                           tb_a_rd_oce        ;
reg                           tb_a_addr_strobe   ;
wire                          tb_a_clk           ;
reg   [B_ADDR_WIDTH   : 0]    tb_b_addr          ;
wire  [B_DATA_WIDTH-1 : 0]    tb_b_wrdata        ;
wire  [B_DATA_WIDTH-1 : 0]    tb_b_rddata        ;
reg                           tb_b_wr_en         ;
reg                           tb_b_clk_en        ;
reg                           tb_b_rst           ;
reg   [B_BE_WIDTH-1   : 0]    tb_b_wr_byte_en    ;
reg                           tb_b_rd_oce        ;
reg                           tb_b_addr_strobe   ;
wire                          tb_b_clk           ;

reg                           tb_a_rd_comp        ;
reg                           tb_a_rd_comp_dly    ;
reg                           tb_a_rd_comp_2dly   ;
reg   [A_DATA_WIDTH-1 : 0]    tb_a_rddata_cnt     ;
reg   [A_DATA_WIDTH-1 : 0]    tb_a_rddata_cnt_dly ;
reg   [A_DATA_WIDTH-1 : 0]    tb_a_expected_data  ;
reg   [A_DATA_WIDTH-1 : 0]    tb_a_wrdata_cnt     ;
reg                           tb_b_rd_comp        ;
reg                           tb_b_rd_comp_dly    ;
reg                           tb_b_rd_comp_2dly   ;
reg   [B_DATA_WIDTH-1 : 0]    tb_b_rddata_cnt     ;
reg   [B_DATA_WIDTH-1 : 0]    tb_b_rddata_cnt_dly ;
reg   [B_DATA_WIDTH-1 : 0]    tb_b_expected_data  ;
reg   [B_DATA_WIDTH-1 : 0]    tb_b_wrdata_cnt     ;
reg                           check_err_a         ;
reg                           check_err_b         ;
reg   [3:0]                   results_cnt_a       ;
reg   [3:0]                   results_cnt_b       ;

//************************************************************ CGU ****************************************************************************
initial
begin
    tb_a_addr        = {A_ADDR_WIDTH{1'b0}} ;
    tb_a_wr_en       = 1'b0 ;
    tb_a_clk_en      = 1'b0 ;
    tb_a_rd_oce      = 1'b0 ;
    tb_a_addr_strobe = 1'b0 ;
    tb_a_rd_comp     = 1'b0 ;

    tb_b_addr        = {B_ADDR_WIDTH{1'b0}} ;
    tb_b_wr_en       = 1'b0 ;
    tb_b_clk_en      = 1'b0 ;
    tb_b_rd_oce      = 1'b0 ;
    tb_b_addr_strobe = 1'b0 ;
    tb_b_rd_comp     = 1'b0 ;

    if (A_CLK_EN == 1'b1)
        tb_a_clk_en = 1'b1 ;
    else
        tb_a_clk_en = 1'b0 ;

    if (B_CLK_EN == 1'b1)
        tb_b_clk_en = 1'b1 ;
    else
        tb_b_clk_en = 1'b0 ;

    if(A_RD_OCE_EN == 1'b1)
        tb_a_rd_oce = 1'b1 ;
    else
        tb_a_rd_oce = 1'b0 ;

    if(B_RD_OCE_EN == 1'b1)
        tb_b_rd_oce = 1'b1 ;
    else
        tb_b_rd_oce = 1'b0 ;

    if (WR_BYTE_EN == 1'b1)
    begin
        tb_a_wr_byte_en  = {A_BE_WIDTH{1'b1}} ;
        tb_b_wr_byte_en  = {B_BE_WIDTH{1'b1}} ;
    end
    else
    begin
        tb_a_wr_byte_en  = {A_BE_WIDTH{1'b0}} ;
        tb_b_wr_byte_en  = {B_BE_WIDTH{1'b0}} ;
    end

    if (A_ADDR_STROBE_EN == 1'b1)
        tb_a_addr_strobe = 1'b0 ;
    else
        tb_a_addr_strobe = 1'b0 ;

    if (B_ADDR_STROBE_EN == 1'b1)
        tb_b_addr_strobe = 1'b0 ;
    else
        tb_b_addr_strobe = 1'b0 ;

end

initial
begin
forever #(T_CLK_PERIOD/2) a_clk = ~a_clk ;
end

initial
begin
forever #(T_CLK_PERIOD/2) b_clk = ~b_clk ;
end

assign tb_a_clk = (A_CLK_OR_POL_INV == 1) ? ~a_clk : a_clk;
assign tb_b_clk = (B_CLK_OR_POL_INV == 1) ? ~b_clk : b_clk;

task write_dpram_a ;
    input write_dpram_a ;
    
    begin
        tb_a_wr_en   = 1'b0 ;
        tb_a_addr    = {A_ADDR_WIDTH+1{1'b0}} ;
        while (tb_a_addr <= 2**A_ADDR_WIDTH-1)
        begin
            @(posedge a_clk) ;
            tb_a_wr_en = 1'b1 ;
            tb_a_addr  = tb_a_addr + {{A_ADDR_WIDTH-1{1'b0}},1'b1} ;
        end
        tb_a_wr_en = 1'b0 ;
    end
endtask

task write_dpram_b ;
    input write_dpram_b ;
    
    begin
        tb_b_wr_en = 1'b0 ;
        tb_b_addr  = {B_ADDR_WIDTH+1{1'b0}} ;
        while (tb_b_addr <= 2**B_ADDR_WIDTH-1)
        begin
            @(posedge b_clk) ;
            tb_b_wr_en = 1'b1 ;
            tb_b_addr  = tb_b_addr + {{B_ADDR_WIDTH-1{1'b0}},1'b1} ;
        end
        tb_b_wr_en = 1'b0 ;
    end
endtask

task read_dpram_a ;
    input read_dpram_a ;
    
    begin
        tb_a_addr  = {A_ADDR_WIDTH+1{1'b0}} ;
        while (tb_a_addr <= 2**A_ADDR_WIDTH-1)
        begin
            @(posedge a_clk) ;
            tb_a_rd_comp = 1'b1 ;
            tb_a_addr    = tb_a_addr + {{A_ADDR_WIDTH-1{1'b0}},1'b1} ;
        end
        tb_a_rd_comp = 1'b0 ;
    end
endtask

task read_dpram_b ;
    input read_dpram_b ;
    
    begin
        tb_b_addr  = {B_ADDR_WIDTH+1{1'b0}} ;
        while (tb_b_addr <= 2**B_ADDR_WIDTH-1)
        begin
            @(posedge b_clk) ;
            tb_b_rd_comp = 1'b1 ;
            tb_b_addr    = tb_b_addr + {{B_ADDR_WIDTH-1{1'b0}},1'b1} ;
        end
        tb_b_rd_comp = 1'b0 ;
    end
endtask

initial
begin
    tb_a_rst = 1'b1 ;
    tb_b_rst = 1'b0 ;
    a_clk = 1'b0 ;
    b_clk = 1'b0 ;

    #T_RST_TIME;
    tb_a_rst = 1'b0 ;

    #10
    tb_b_rst = 1'b1 ;
    #T_RST_TIME;
    tb_b_rst = 1'b0 ;

    if(INIT_FILE == "NONE")
    begin
        $display("Writing DPRAM from Port A") ;
        write_dpram_a(1) ;
        #10 ;
        $display("Reading DPRAM from Port A") ;
        read_dpram_a(1) ;

        #10;
        $display("Writing DPRAM from Port A") ;
        write_dpram_a(1) ;
        #10;
        $display("Reading DPRAM from Port B") ;
        read_dpram_b(1) ;
 
        #10;
        $display("Writing DPRAM from Port B") ;
        write_dpram_b(1) ;
        #10;
        $display("Reading DPRAM from Port B") ;
        read_dpram_b(1) ;
 
        #10;
        $display("Writing DPRAM from Port B") ;
        write_dpram_b(1) ;
        #10;
        $display("Reading DPRAM from Port A") ;
        read_dpram_a(1) ;
        #10;

        $display ("DPRAM simulation is done") ;
        if ((|results_cnt_a) || (|results_cnt_b))
        begin
            $display ("Simulation Failed due to Error Found.") ;
        end
        else
        begin
            $display ("Simulation Success.") ;
        end
    end
    else
    begin
        $display ("Reading initialized DPRAM") ;
        read_dpram_a(1) ;
        #10
        $display ("DPRAM simulation is done") ;
        $display ("Simulation Success.") ;
    end

    #500
    $finish;
end
//check logic

always @(posedge a_clk or posedge tb_a_rst)
begin
    if (tb_a_rst)
        tb_a_wrdata_cnt <= {A_DATA_WIDTH{1'b1}} ;
    else if (!tb_a_wr_en)
        tb_a_wrdata_cnt <= {A_DATA_WIDTH{1'b1}} ;
    else
        tb_a_wrdata_cnt <= tb_a_wrdata_cnt - {{A_DATA_WIDTH-1{1'b0}},1'b1} ;
end

always @(posedge b_clk or posedge tb_b_rst)
begin
    if (tb_b_rst)
        tb_b_wrdata_cnt <= {B_DATA_WIDTH{1'b1}} ;
    else if (!tb_b_wr_en)
        tb_b_wrdata_cnt <= {B_DATA_WIDTH{1'b1}} ;
    else
        tb_b_wrdata_cnt <= tb_b_wrdata_cnt - {{B_DATA_WIDTH-1{1'b0}},1'b1} ;
end

assign tb_a_wrdata = tb_a_wrdata_cnt;
assign tb_b_wrdata = tb_b_wrdata_cnt;

always@(posedge a_clk or posedge tb_a_rst)
begin
    if(tb_a_rst)
        tb_a_rddata_cnt <= {A_DATA_WIDTH{1'b1}} ;
    else if (!tb_a_rd_comp)
        tb_a_rddata_cnt <= {A_DATA_WIDTH{1'b1}} ;
    else if (((A_RD_OCE_EN == 1'b1) && (tb_a_rd_oce))
           || (A_RD_OCE_EN == 1'b0))
        tb_a_rddata_cnt <= tb_a_rddata_cnt - {{A_DATA_WIDTH-1{1'b0}},1'b1} ;
end

always @(posedge tb_a_clk or posedge tb_a_rst)
begin
    if (tb_a_rst)
        tb_a_rddata_cnt_dly <= {A_DATA_WIDTH{1'b0}} ;
    else
        tb_a_rddata_cnt_dly <= tb_a_rddata_cnt ;
end

always @(posedge tb_a_clk or posedge tb_a_rst)
begin
    if (tb_a_rst)
    begin
        tb_a_rd_comp_dly  <= 1'b0;
        tb_a_rd_comp_2dly <= 1'b0;
    end
    else
    begin
        tb_a_rd_comp_dly  <= tb_a_rd_comp;
        tb_a_rd_comp_2dly <= tb_a_rd_comp_dly;
    end
end

always @(posedge tb_a_clk or posedge tb_a_rst)
begin
    if (tb_a_rst)
        tb_a_expected_data <= {A_DATA_WIDTH{1'b0}} ;
    else if (A_RD_OCE_EN == 1'b1)
    begin
        if (tb_a_rd_oce)
            tb_a_expected_data <= tb_a_rddata_cnt_dly ;
    end
    else if (A_OUTPUT_REG == 1'b1)
        tb_a_expected_data <= tb_a_rddata_cnt_dly ;
    else
        tb_a_expected_data <= tb_a_rddata_cnt ;
end

always@(posedge b_clk or posedge tb_b_rst)
begin
  if(tb_b_rst)
      tb_b_rddata_cnt <= {B_DATA_WIDTH{1'b1}} ;
  else if (!tb_b_rd_comp)
      tb_b_rddata_cnt <= {B_DATA_WIDTH{1'b1}} ;
  else if (((B_RD_OCE_EN == 1'b1) && (tb_b_rd_oce))
         || (B_RD_OCE_EN == 1'b0))
      tb_b_rddata_cnt <= tb_b_rddata_cnt - {{B_DATA_WIDTH-1{1'b0}},1'b1} ;
end

always @(posedge tb_b_clk or posedge tb_b_rst)
begin
    if (tb_b_rst)
        tb_b_rddata_cnt_dly <= {B_DATA_WIDTH{1'b0}} ;
    else
        tb_b_rddata_cnt_dly <= tb_b_rddata_cnt ;
end

always @(posedge tb_b_clk or posedge tb_b_rst)
begin
    if (tb_b_rst)
    begin
        tb_b_rd_comp_dly  <= 1'b0 ;
        tb_b_rd_comp_2dly <= 1'b0 ;
    end
    else
    begin
        tb_b_rd_comp_dly  <= tb_b_rd_comp ;
        tb_b_rd_comp_2dly <= tb_b_rd_comp_dly ;
    end
end

always @(posedge tb_b_clk or posedge tb_b_rst)
begin
    if (tb_b_rst)
        tb_b_expected_data <= {B_DATA_WIDTH{1'b0}} ;
    else if (B_RD_OCE_EN == 1'b1)
    begin
        if (tb_b_rd_oce)
            tb_b_expected_data <= tb_b_rddata_cnt_dly ;
    end
    else if (B_OUTPUT_REG == 1'b1)
        tb_b_expected_data <= tb_b_rddata_cnt_dly ;
    else
        tb_b_expected_data <= tb_b_rddata_cnt ;
end

always@(posedge tb_a_clk or posedge tb_a_rst)
begin
    if(tb_a_rst)
        check_err_a <= 1'b0;
    else if(INIT_FILE == "NONE")
    begin
        if (((A_RD_OCE_EN == 1'b1) && (tb_a_rd_comp_2dly) && (tb_a_rd_oce))
         || ((A_OUTPUT_REG == 1'b0) && (tb_a_rd_comp_dly))
         || ((A_OUTPUT_REG == 1'b1) && (tb_a_rd_comp_2dly)))
            check_err_a <= (tb_a_expected_data != tb_a_rddata) ;
        else
            check_err_a <= 1'b0;
    end 
    else
        check_err_a <= 1'b0;
end

always@(posedge tb_b_clk or posedge tb_b_rst)
begin
    if(tb_b_rst)
        check_err_b <= 1'b0;
    else if(INIT_FILE == "NONE")
    begin
        if (((B_RD_OCE_EN == 1'b1) && (tb_b_rd_comp_2dly) && (tb_b_rd_oce))
         || ((B_OUTPUT_REG == 1'b0) && (tb_b_rd_comp_dly))
         || ((B_OUTPUT_REG == 1'b1) && (tb_b_rd_comp_2dly)))
            check_err_b <= (tb_b_expected_data != tb_b_rddata) ;
        else
            check_err_b <= 1'b0;
    end 
    else
        check_err_b <= 1'b0;
end

always @(posedge tb_a_clk or posedge tb_a_rst)
begin
    if (tb_a_rst)
        results_cnt_a <= 3'b000;
    else if (&results_cnt_a)
        results_cnt_a <= 3'b100;
    else if (check_err_a)
        results_cnt_a <= results_cnt_a + 3'd1;
end

always @(posedge tb_b_clk or posedge tb_b_rst)
begin
    if (tb_b_rst)
        results_cnt_b <= 3'b000;
    else if (&results_cnt_b)
        results_cnt_b <= 3'b100;
    else if (check_err_b)
        results_cnt_b <= results_cnt_b + 3'd1;
end

//***************************************************************** DUT  INST **************************************************************************************
GTP_GRS GRS_INST(
    .GRS_N(1'b1)
    ) ;

DPRAM U_DPRAM (
    .a_addr        ( tb_a_addr[A_ADDR_WIDTH-1 : 0] ),
    .a_wr_data     ( tb_a_wrdata                   ),
    .a_rd_data     ( tb_a_rddata                   ),
    .a_wr_en       ( tb_a_wr_en                    ),

    .a_rst         ( tb_a_rst                      ),

    .a_clk         ( a_clk                         ),
    .b_addr        ( tb_b_addr[B_ADDR_WIDTH-1 : 0] ),
    .b_wr_data     ( tb_b_wrdata                   ),
    .b_rd_data     ( tb_b_rddata                   ),
    .b_wr_en       ( tb_b_wr_en                    ),

    .b_rst         ( tb_b_rst                      ),

    .b_clk         ( b_clk                         )
    ) ;

endmodule
