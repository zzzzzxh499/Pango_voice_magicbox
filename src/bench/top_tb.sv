//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2022 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module top_tb ();

GTP_GRS GRS_INST(
    .GRS_N (1'b1)
);

reg clk, rstn;
reg sclk;
reg pix_clk; 
reg [4:0] cnt;
integer i = 0;

wire lrclk;
reg  sdin;
reg [15:0] test_mem_l [2**17-1:0];
reg [15:0] test_mem_r [2**17-1:0];
wire [15:0] test_data_l;
wire [15:0] test_data_r;

//HDMI CTRL
wire rst_n_hdmi;
wire iic_hdmi_scl;
wire iic_hdmi_sda;
wire iic_tx_scl;
wire iic_tx_sda;
//HDMI IN
wire vs_in,hs_in,de_in;
wire [7:0] r_in,g_in,b_in;
//HDMI OUT
wire vs_out,hs_out,de_out;
wire [7:0] r_out,g_out,b_out;
//Micropho
wire es7243_scl;
wire es7243_sda;
wire es0_mclk;
wire es0_sdin,es0_dsclk,es0_alrck;
//ALARM
wire es8156_scl;
wire es8156_sda;
wire es1_mclk;
wire es1_sdout;
wire es1_dsclk,es1_dlrc;
//UART
wire uart_rx,uart_tx;
reg stream_rstn=0;

parameter   CLK_P             = 10      ; // 50MHz
parameter   SCLK_P            = 38.46   ; //26MHz
parameter   PIXCLK_P          = 6.734   ;//148.5M   

initial begin
    clk = 1'b1;
    forever 
        #(CLK_P/2) clk = ~clk;
end

initial begin
    pix_clk = 1'b1;
    forever 
        #(PIXCLK_P/2) pix_clk = ~pix_clk;
end
////////////////////////  i2s   ////////////////////////////////
initial begin
    sclk = 1'b0;
    forever 
        #(SCLK_P/2) sclk = ~sclk;
end

initial $readmemh("../mcode/sound_data.dat",test_mem_r);
initial $readmemh("../mcode/sound_data.dat",test_mem_l);

always @(posedge sclk) begin
    if(~stream_rstn) cnt <= 0;
    else cnt <= cnt + 1;
end

assign lrclk = cnt[4];

always @(negedge lrclk)i <= ~stream_rstn ? 0 : i + 1;

assign test_data_r = test_mem_r[i];
assign test_data_l = test_mem_l[i];
always @(posedge sclk) sdin <= lrclk ? test_data_r[15-cnt[3:0]] : test_data_l[15-cnt[3:0]];
//////////////////////////////////////////////////////////////////


top #(
    .SIM(1)
)top ( 
    //system
    .sys_clk    (clk    ),
    .keys       ({rstn,7'd0}   ),
    //HDMI CTRL
    .rstn_out_hdmi  (rst_n_hdmi),
    .iic_scl    (iic_tx_scl),
    .iic_sda    (iic_tx_sda),
    .iic_tx_scl (),
    .iic_tx_sda (),
    .pixclk_in  (pix_clk),
    //HDMI IN
    .vs_in      (vs_in),
    .hs_in      (hs_in),
    .de_in      (de_in),
    .r_in       (r_in),
    .g_in       (g_in),
    .b_in       (b_in),
    //HDMI OUT
    .vs_out      (vs_out),
    .hs_out      (hs_out),
    .de_out      (de_out),
    .r_out       (r_out),
    .g_out       (g_out),
    .b_out       (b_out),
    //UART
    .uart_rx    (uart_tx),
    .uart_tx    (uart_rx),
    //ES7243E  ADC  in
    .es7243_scl (es7243_scl),          
    .es7243_sda (es7243_sda),          
    .es0_mclk   (es0_mclk  ),          
    .es0_sdin   (es0_sdin  ),          
    .es0_dsclk  (es0_dsclk ),          
    .es0_alrck  (es0_alrck ), 
    //ES8156   DAC   out
    .es8156_scl (es8156_scl),      
    .es8156_sda (es8156_sda),      
    .es1_mclk   (es1_mclk  ),      
    .es1_sdin   (es1_sdin  ),      
    .es1_sdout  (es1_sdout ),      
    .es1_dsclk  (es1_dsclk ),      
    .es1_dlrc   (es1_dlrc  )
);

assign es0_dsclk = sclk;
assign es0_sdin = sdin;
assign es0_alrck = lrclk;
assign es7243_sda = 1'b1;
assign es8156_sda = 1'b1;
//------------------------------------------------------
initial begin
    rstn = 1'b0;
    stream_rstn = 1'b0;
    #1000
    rstn = 1'b1;
    #10000
    @(posedge sclk) stream_rstn = 1'b1;
    @(posedge sclk)
    force top_tb.top.es7243_init = 1'b1;
    force top_tb.top.es8156_init = 1'b1;
end    

wire i_aclk = top_tb.top.clk_100M;
wire i_axi4s_data_tvalid = top_tb.top.u_fft_wrapper.i_axi4s_data_tvalid;
wire o_axi4s_data_tready = top_tb.top.u_fft_wrapper.o_axi4s_data_tready;
wire [31:0] i_axi4s_data_tdata = top_tb.top.u_fft_wrapper.i_axi4s_data_tdata;
wire o_axi4s_data_tvalid = top_tb.top.u_fft_wrapper.o_axi4s_data_tvalid;
wire [63:0] o_axi4s_data_tdata = top_tb.top.u_fft_wrapper.o_axi4s_data_tdata;
wire [15:0] tx_data = top_tb.top.stream_ctrler.txff_data;

wire [26:0] fft_imag = top_tb.top.mfcc_u.fft_imag;
wire [26:0] fft_real = top_tb.top.mfcc_u.fft_real;
wire fft_valid = top_tb.top.mfcc_u.fft_valid;
wire  [63:0] fbe = top_tb.top.mfcc_u.fbe;
wire fbe_valid = top_tb.top.mfcc_u.fbe_valid;
wire [15:0] logFBE = top_tb.top.mfcc_u.log_fbe;
wire logFBE_valid = top_tb.top.mfcc_u.fbe_valid_d[8];
wire [15:0] mfcc = top_tb.top.mfcc_u.mfcc;
wire mfcc_valid = top_tb.top.mfcc_u.mfcc_valid;


integer file1,file2,file3,file4,file5,file6;
initial begin
file1 = $fopen("../mcode/fft_imag.dat");
file2 = $fopen("../mcode/fft_real.dat");
file3 = $fopen("../mcode/log_fbe.dat");
file4 = $fopen("../mcode/mfcc_data.dat");
file5 = $fopen("../mcode/fbe.dat");
file6 = $fopen("../mcode/data_org.dat");
end

always @(posedge i_aclk)
if(fft_valid) $fdisplay(file1,"%d",$signed(fft_imag));

always @(posedge i_aclk)
if(fft_valid) $fdisplay(file2,"%d",$signed(fft_real));

always @(posedge i_aclk)
if(logFBE_valid) $fdisplay(file3,"%d",$signed(logFBE));

always @(posedge i_aclk)
if(mfcc_valid) $fdisplay(file4,"%d",$signed(mfcc));

always @(posedge i_aclk)
if(fbe_valid) $fdisplay(file5,"%d",$unsigned(fbe));

always @(posedge i_aclk)
if(i_axi4s_data_tvalid&&o_axi4s_data_tready) $fdisplay(file6,"%d",$signed(i_axi4s_data_tdata[15:0]));

// wire sclk = top_tb.top.stream_ctrler.sclk;


// wire txff_wren = top_tb.top.stream_ctrler.txff_wren;
// wire [15:0] txff_data = top_tb.top.stream_ctrler.txff_data;

// always @(posedge i_aclk)
// if(txff_wren) $fdisplay(file2,"%b",txff_data);

hdmi_test  hdmi_0(
   // . sys_clk()       ,// input system clock 50MHz    
    . rstn_out()      ,
    . iic_tx_scl(iic_tx_scl)    ,
   .  iic_tx_sda(iic_tx_sda)    ,
    . led_int()       ,
//hdmi_out 
    .  pix_clk(pix_clk     )      ,//pixclk                           
    .  vs_out (vs_in)       , 
    .  hs_out (hs_in)       , 
    .  de_out (de_in)       ,
    .  r_out   (r_in)     , 
    .  g_out   (g_in)      , 
    .  b_out   (b_in)      
);


endmodule