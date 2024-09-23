

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
// Filename:TB logfbe_buff_tb.v
//////////////////////////////////////////////////////////////////////////////

`timescale   1ns / 1ps

module  logfbe_buff_tb ();

    localparam T_CLK_PERIOD = 10  ; //clock a half perid
    localparam T_RST_TIME   = 200 ; //reset time

    localparam ADDR_WIDTH = 5 ; //@IPC int 4,10

    localparam DATA_WIDTH = 16 ; //@IPC int 1,256

    localparam OUT_REG = 0 ; //@IPC bool

    localparam RST_TYPE = "ASYNC" ; //@IPC enum ASYNC,SYNC

    localparam FIFO_TYPE = "SYNC_FIFO" ; //@IPC enum ASYNC_FIFO,SYNC_FIFO

    localparam ALMOST_FULL_NUM = 26 ; //@IPC int 4,1024

    localparam ALMOST_EMPTY_NUM = 4 ; //@IPC int 4,1024

    localparam WR_WATER_LEVEL_ENABLE = 0 ; //@IPC bool

    localparam RD_WATER_LEVEL_ENABLE = 0 ; //@IPC bool


// variable declaration
    reg                       clk_tb            ;
    reg                       tb_rst            ;
    reg   [DATA_WIDTH-1:0]    tb_wrdata         ;
    wire  [DATA_WIDTH-1:0]    tb_rddata         ;
    reg                       tb_wr_en          ;
    reg                       tb_rd_en          ;
    
    wire                      tb_full           ;
    wire                      tb_empty          ;
    wire                      tb_almost_full    ;
    wire                      tb_almost_empty   ;
    reg                       check_err         ;
    reg   [2:0]               results_cnt       ;
    reg   [ADDR_WIDTH:0]      write_numbers     ;
    reg   [ADDR_WIDTH:0]      read_numbers      ;
    reg   [DATA_WIDTH-1:0]    tb_rddata_cnt     ;
    wire  [DATA_WIDTH-1:0]    tb_rddata_expect  ;
    reg   [DATA_WIDTH-1:0]    tb_rddata_cnt_d1  ;
    reg   [DATA_WIDTH-1:0]    tb_rddata_cnt_d2  ;

    wire                      cnt_en            ;
//********************************************** CGU ****************************************************************************
//generate clk_tb
initial
begin
    clk_tb = 0;
    forever #(T_CLK_PERIOD/2)  clk_tb = ~clk_tb ;
end

//********************************************** DGU ********************************************************************************

assign cnt_en = tb_rd_en && (!tb_empty) ;


always@(posedge clk_tb or posedge tb_rst) begin
  if(tb_rst)
      tb_rddata_cnt<=0;
  else if ( cnt_en )
      tb_rddata_cnt <= tb_rddata_cnt + 1;
  else
      tb_rddata_cnt <= 0;
end

always@(posedge clk_tb or posedge tb_rst) begin
  if(tb_rst)
  begin
      tb_rddata_cnt_d1<=0;
  end
  else
  begin
      tb_rddata_cnt_d1 <= tb_rddata_cnt;
  end
end

assign  tb_rddata_expect = (OUT_REG==1) ? tb_rddata_cnt_d1 : tb_rddata_cnt;

initial begin

    tb_rst    = 1;
    tb_wrdata = 0;
    tb_wr_en  = 0;
    tb_rd_en  = 0;

    #T_RST_TIME;
    tb_rst   = 0;
    #15        ;

    //write fifo task
    $display("writing fifo");
    write_fifo;
    #10       ;
    //read fifo task;
    $display("reading fifo");
    read_fifo ;
    #10       ;
    $display("Simulation done");
    if (|results_cnt)
        $display("Simulation Failed due to Error Found.") ;
    else
        $display("Simulation Success.") ;
    #500 ;
    $finish ;
end


//****************************************** DUT  INST **************************************************************************************

always@(negedge clk_tb or posedge tb_rst) begin
    if(tb_rst)
        check_err <=0;
    else if(tb_rd_en == 1'b1)
    begin
        #10;
        if((tb_rddata_expect != tb_rddata) && (!tb_empty))
            check_err <=1;
        else
            check_err <=0;
    end
    else
        check_err <=0;
end

always @(negedge clk_tb or posedge tb_rst)
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
logfbe_buff  U_logfbe_buff (
    .wr_data       (tb_wrdata)          ,
    .wr_en         (tb_wr_en)           ,
    
    .full          (tb_full)            ,
    .almost_full   (tb_almost_full)     ,
    
    .rd_data       (tb_rddata)          ,
    .rd_en         (tb_rd_en)           ,
    
    .empty         (tb_empty)           ,
    
    .clk           (clk_tb)             ,
    .rst           (tb_rst)             ,
    
    .almost_empty  (tb_almost_empty)
);

task write_fifo;

   begin
     tb_wr_en       = 1;
     tb_wrdata      = 0;
     write_numbers  = 0;
     while ( write_numbers < 2**ADDR_WIDTH )
     begin
        @(posedge clk_tb);
        tb_wr_en      = 1'b1;
        tb_wrdata     = tb_wrdata + 1'b1;
        write_numbers = write_numbers + 1'b1;
     end

     tb_wr_en  = 1'b0;
     tb_wrdata = 1'b0;
   end
endtask

task read_fifo;

   begin
     tb_rd_en     = 1'b1;
     read_numbers = 1'b0;
     while (read_numbers < 2**ADDR_WIDTH )
     begin
        @(negedge clk_tb);
        begin
         read_numbers = read_numbers + 1'b1;
        end
     end
   tb_rd_en = 1'b0;
   end
endtask

endmodule

