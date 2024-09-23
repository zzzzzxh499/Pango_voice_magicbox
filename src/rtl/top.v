// `define SIMULATION
module top #(
    parameter SIM = 0
)
(
    input wire        sys_clk         ,//50MHz
    input    [7:0]    keys             /*synthesis PAP_MARK_DEBUG="1"*/,
//HDMI IN
    output            rstn_out_hdmi,
    output            iic_scl,
    inout             iic_sda, 
    output            iic_tx_scl,
    inout             iic_tx_sda, 
    input             pixclk_in,                            
    input             vs_in, 
    input             hs_in, 
    input             de_in,
    input     [7:0]   r_in, 
    input     [7:0]   g_in, 
    input     [7:0]   b_in,  
//HDMI OUT
    output            pixclk_out,                            
    output            vs_out, 
    output            hs_out, 
    output            de_out,
    output     [7:0]  r_out, 
    output     [7:0]  g_out, 
    output     [7:0]  b_out,
// UART
    input             uart_rx,
    output            uart_tx,
//ES7243E  ADC  in
    output            es7243_scl      /*synthesis PAP_MARK_DEBUG="1"*/,//CCLK
    inout             es7243_sda      /*synthesis PAP_MARK_DEBUG="1"*/,//CDATA
    output            es0_mclk        /*synthesis PAP_MARK_DEBUG="1"*/,//MCLK  clk_12M
    input             es0_sdin        /*synthesis PAP_MARK_DEBUG="1"*/,//SDOUT i2s            i2s_sdin
    input             es0_dsclk       /*synthesis PAP_MARK_DEBUG="1"*/,//SCLK  i2s            i2s_sck   
    input             es0_alrck       /*synthesis PAP_MARK_DEBUG="1"*/,//LRCK  i2s            i2s_ws
//ES8156  DAC   out
    output            es8156_scl      /*synthesis PAP_MARK_DEBUG="1"*/,//CCLK
    inout             es8156_sda      /*synthesis PAP_MARK_DEBUG="1"*/,//CDATA 
    output            es1_mclk        /*synthesis PAP_MARK_DEBUG="1"*/,//MCLK  clk_12M
    input             es1_sdin        /*synthesis PAP_MARK_DEBUG="1"*/,//SDOUT 
    output            es1_sdout       /*synthesis PAP_MARK_DEBUG="1"*/,//SDIN  DAC i2s          i2s_sdout
    input             es1_dsclk       /*synthesis PAP_MARK_DEBUG="1"*/,//SCLK  i2s           i2s_sck
    input             es1_dlrc        /*synthesis PAP_MARK_DEBUG="1"*/,//LRCK  i2s      i2s_ws
//ethernet port
    input        rgmii_rxc,
    input        rgmii_rx_ctl,
    input [3:0]  rgmii_rxd,
                 
    output       rgmii_txc,
    output       rgmii_tx_ctl,
    output [3:0] rgmii_txd, 

    output       phy_rstn,
//  
    input             lin_test,
    input             lout_test,
    output  [7:0]     led
);
parameter START_DELAY = SIM ? 20'd1000 : 20'h50000; 

localparam IFFT_ONLY = 3'b001,
           L_ONLY = 3'b010,
           R_ONLY = 3'b100,
           DECHO = 3'b011;

localparam WHITE  = 24'b11111111_11111111_11111111;  //RGB888 WHITE
localparam BLACK  = 24'b00000000_00000000_00000000;  //RGB888 BALCK
localparam RED    = 24'b11111111_00001100_00000000;  //RGB888 RED
localparam GREEN  = 24'b00000000_11111111_00000000;  //RGB888 GREEN
localparam BLUE   = 24'b00000000_00000000_11111111;  //RGB888 BLUE

//voice_loop wire/reg
wire        init_over;
wire led_eth;
wire adc_dac_int;
wire [15:0] rx_data_tmp;/*synthesis PAP_MARK_DEBUG="1"*/
wire [15:0] rx_data;/*synthesis PAP_MARK_DEBUG="1"*/
wire rx_l_vld;
wire rx_r_vld;
wire [15:0] ldata,rdata;
wire [15:0] ifft_data; 
reg  [15:0] tx_ldata,tx_rdata;/*synthesis PAP_MARK_DEBUG="1"*/
reg  [15:0] tx_ldata_tmp,tx_rdata_tmp;/*synthesis PAP_MARK_DEBUG="1"*/
wire [15:0] decho_data;
wire [15:0] ifft_data_re,ifft_data_im;

wire              xn_axi4s_data_tready;
wire              xn_axi4s_data_tvalid;
wire [31:0]       xn_axi4s_data_tdata ;
wire              xn_axi4s_data_tlast ;
wire              xn_axi4s_cfg_tvalid ;
wire              xn_axi4s_cfg_tdata  ;
wire              stat                ;
wire [2:0]        alm                 ;

wire                          xk_axi4s_data_tvalid;
wire   [63:0]                 xk_axi4s_data_tdata ;
wire                          xk_axi4s_data_tlast ;
wire   [63:0]                 xk_axi4s_data_tuser ;

wire [4:0] current_state;
wire [31:0] tdata_fifo;
wire [31:0] freq_data;
wire freq_valid;
wire freq_last;
wire [9:0] read_addr;
wire [9:0] ram_addr;
wire girl2boy,boy2girl;
wire denoise;
wire separate1,separate2;
wire switch_display;
wire [2:0] speaker_ctrl;
wire nouput;
reg  l_level,r_level;

wire fft_stored,fft_storing;

wire signed [15:0] mfcc;
wire mfcc_valid;

wire data_rcg_valid;
wire [15:0] mfcc_means;
wire mfcc_means_valid;

wire data_hi = ^rx_data[15:5]; //abs rx_data > 32
wire rstn_button7 = keys[7];


wire        locked0,locked1,locked         ;
wire        rstn_out       /*synthesis PAP_MARK_DEBUG="1"*/;
wire        es7243_init       /*synthesis PAP_MARK_DEBUG="1"*/;
wire        es8156_init       /*synthesis PAP_MARK_DEBUG="1"*/;
wire        clk_12M        /*synthesis PAP_MARK_DEBUG="1"*/;
wire        clk_100M;     /*synthesis PAP_MARK_DEBUG="1"*/;
wire        clk_50M;        /*synthesis PAP_MARK_DEBUG="1"*/

PLL u_pll (
  .clkin1       (sys_clk   ),   // input//50MHz
  .pll_lock     (locked0    ),   // output
  .clkout0      (clk_12M   )    // output//12.288MHz
);
PLL0 u_pll0 (
  .clkin1       (sys_clk   ),   // input//50MHz
  .pll_lock     (locked1    ),   // output
  .clkout0      (clk_100M  ),
  .clkout1      (clk_50M   ),
  .clkout2      (cfg_clk)       // output//10Mhz
);

assign locked = locked0 && locked1;
assign es0_mclk    =    clk_12M;

reg  [19:0]                 cnt_12M   ;
reg                         ce        /*synthesis PAP_MARK_DEBUG="1"*/; 
    always @(posedge clk_12M)
    begin
    	if(!locked|!rstn_button7)
    	    cnt_12M <= 20'h0;
    	else
    	begin
    		if(cnt_12M == 20'h10000)
    		    cnt_12M <= cnt_12M;
    		else
    		    cnt_12M <= cnt_12M + 1'b1;
    	end
    end

    always @(posedge clk_12M)
    begin
    	if(!locked|!rstn_button7)
    	    ce <= 1'h0;
    	else
    	begin
    		if((cnt_12M <= 20'h1)|(cnt_12M == 20'h10000))
    		    ce <= 1'h1;
    		else
    		    ce <= 1'h0;
    	end
    end



assign es1_mclk    =    clk_12M;
assign clk_test    =    clk_12M;
reg  [19:0]                 rstn_1ms            /*synthesis PAP_MARK_DEBUG="1"*/;
    always @(posedge clk_12M)
    begin
    	if(!locked|!rstn_button7)
    	    rstn_1ms <= 20'h0;
    	else
    	begin
    		if(rstn_1ms == START_DELAY)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == START_DELAY);

ES7243E_reg_config	ES7243E_reg_config(
    	.clk_12M                 (clk_12M           ),//input
    	.rstn                    (rstn_out          ),//input	
    	.i2c_sclk                (es7243_scl        ),//output
    	.i2c_sdat                (es7243_sda        ),//inout
    	.reg_conf_done           (es7243_init       ),//output config_finished
        .clock_i2c               (clock_i2c)
    );
ES8156_reg_config	ES8156_reg_config(
    	.clk_12M                 (clk_12M           ),//input
    	.rstn                    (rstn_out            ),//input	
    	.i2c_sclk                (es8156_scl        ),//output
    	.i2c_sdat                (es8156_sda        ),//inout
    	.reg_conf_done           (es8156_init       )//output config_finished
    );
assign adc_dac_int = es7243_init && es8156_init;
//ES7243E demo////////////////////////////////////////////////////////////////////////////////////////////

assign es0_mclk_demo=es0_mclk;
//////////////////////////////////////////////////////////////////////////////////////////////
//ES7243E
pgr_i2s_rx#(
    .DATA_WIDTH(16)
)ES7243_i2s_rx(
    .rst_n          (es7243_init      ),// input

    .sck            (es0_dsclk        ),// input 48K*32=1.536M
    .ws             (es0_alrck        ),// input 48K
    .sda            (es0_sdin         ),// input

    .data           (rx_data_tmp      ),// output[15:0]
    .l_vld          (rx_l_vld         ),// output
    .r_vld          (rx_r_vld         ) // output
);
//ES8156
pgr_i2s_tx#(
    .DATA_WIDTH(16)
)ES8156_i2s_tx(
    .rst_n          (es8156_init    ),// input

    .sck            (es1_dsclk      ),// input  //SCLK  i2s
    .ws             (es1_dlrc       ),// input  //LRCK  i2s
    .sda            (es1_sdout      ),// output //SDIN  DAC i2s

    .ldata          (tx_ldata          ),// input[15:0]
    .l_req          (          ),// output
    .rdata          (tx_rdata          ),// input[15:0]
    .r_req          (          ) // output
);
reg [2:0] speaker_ctrl_d0,speaker_ctrl_d1;
reg nouput_d0,nouput_d1;
always @(posedge es1_dsclk)
if(~es8156_init) begin
    speaker_ctrl_d0 <= 3'b0;
    speaker_ctrl_d1 <= 3'b0;
end
else begin
    speaker_ctrl_d0 <= speaker_ctrl;
    speaker_ctrl_d1 <= speaker_ctrl_d0;
end
always @(posedge es0_dsclk)
if(~es8156_init) begin
    nouput_d0 <= 1'b1;
    nouput_d1 <= 1'b1;
end
else begin
    nouput_d0 <= nouput;
    nouput_d1 <= nouput_d0;
end

always @(posedge es1_dsclk) begin
if(~adc_dac_int) begin
    tx_ldata_tmp = 16'd0;
    tx_rdata_tmp = 16'd0;
end
case(speaker_ctrl_d1)
IFFT_ONLY: begin // FFT->IFFT OUT
    tx_ldata_tmp = ifft_data;
    tx_rdata_tmp = ifft_data;
end
L_ONLY: begin // LEFT CHANNEL ONLY
    tx_ldata_tmp = ldata;
    tx_rdata_tmp = ldata;
end
R_ONLY:begin // RIGHT CHANNEL ONLY
    tx_ldata_tmp = rdata;
    tx_rdata_tmp = rdata;
end
DECHO:begin// ECHO DES OUT
    tx_ldata_tmp = decho_data;
    tx_rdata_tmp = decho_data;
end
default:begin // DIRECT LOOP
    tx_ldata_tmp = ldata;
    tx_rdata_tmp = rdata;
end
endcase
end

always @(*)
begin
    tx_ldata = nouput_d1 ? 16'd0 : tx_ldata_tmp;
    tx_rdata = nouput_d1 ? 16'd0 : tx_rdata_tmp;
end


assign rx_data = rx_data_tmp;

////////////////////////////////////////////LOOP//////////////////////////////////////////////////
i2s_loop#(
    .DATA_WIDTH(16)
)i2s_loop(
    .rst_n          (adc_dac_int),// input
    .sck            (es0_dsclk  ),// input
    .ldata          (ldata      ),// output[15:0]
    .rdata          (rdata      ),// output[15:0]
    .data           (rx_data    ),// input[15:0]
    .r_vld          (rx_r_vld   ),// input
    .l_vld          (rx_l_vld   ) // input
);
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////

hann stream_ctrler(
     .rst_n                 (adc_dac_int)
    ,.sclk                  (es0_dsclk)
    ,.l_lvd                 (rx_l_vld)
    ,.rx_data               (rx_data)
    ,.l_lvd_out             (l_lvd_out)
    ,.tx_data               (ifft_data)
    ,.i_aclk                (clk_100M)    
    ,.o_axi4s_cfg_tvalid    (xn_axi4s_cfg_tvalid) 
    ,.o_axi4s_cfg_tdata     (xn_axi4s_cfg_tdata)           
    ,.i_axi4s_data_tready   (xn_axi4s_data_tready)
    ,.o_axi4s_data_tvalid   (xn_axi4s_data_tvalid)
    ,.o_axi4s_data_tdata    (xn_axi4s_data_tdata) 
    ,.o_axi4s_data_tlast    (xn_axi4s_data_tlast) 
    ,.i_axi4s_data_tvalid   (xk_axi4s_data_tvalid)
    ,.i_axi4s_data_tdata    (xk_axi4s_data_tdata) 
    ,.i_axi4s_data_tlast    (xk_axi4s_data_tlast) 
    ,.i_stat                (stat)
    //algorithm interface
    ,.current_state         (current_state)
    ,.fft_stored            (fft_stored)
    ,.fft_storing           (fft_storing)
    ,.freq_data             (freq_data)
    ,.freq_valid            (freq_valid)
    ,.freq_last             (freq_last)
);

ipsxb_fft_demo_r2_1024  u_fft_wrapper ( 
    .i_aclk                 (clk_100M            ),

    .i_axi4s_data_tvalid    (xn_axi4s_data_tvalid),
    .i_axi4s_data_tdata     (xn_axi4s_data_tdata ),
    .i_axi4s_data_tlast     (xn_axi4s_data_tlast ),
    .o_axi4s_data_tready    (xn_axi4s_data_tready),
    .i_axi4s_cfg_tvalid     (xn_axi4s_cfg_tvalid ),
    .i_axi4s_cfg_tdata      (xn_axi4s_cfg_tdata  ),
    .o_axi4s_data_tvalid    (xk_axi4s_data_tvalid),
    .o_axi4s_data_tdata     (xk_axi4s_data_tdata ),
    .o_axi4s_data_tlast     (xk_axi4s_data_tlast ),
    .o_axi4s_data_tuser     (xk_axi4s_data_tuser ),
    .o_alm                  (alm                 ),
    .o_stat                 (stat                )
);

mfcc_u mfcc_u(
    .clk(clk_100M),
    .rst_n(adc_dac_int),
    .fft_valid(current_state==5'h04 && xk_axi4s_data_tvalid),
    .fft_data(xk_axi4s_data_tdata),
    .mfcc(mfcc),
    .mfcc_valid(mfcc_valid)
);

mfcc_avg mfcc_avg_u
(
    .clk                (clk_100M),
    .rst_n              (adc_dac_int),
    .data_valid         (data_rcg_valid),
    .mfcc_valid         (mfcc_valid),
    .mfcc               (mfcc),
    .mfcc_means         (mfcc_means),
    .mfcc_means_valid   (mfcc_means_valid)
);

voice_recgnize voice_recgnize(
    .clk                (clk_100M),
    .rst_n              (adc_dac_int),
    .mfcc_means         (mfcc_means),
    .mfcc_means_valid   (mfcc_means_valid),
    .data_hi            (data_hi),
    .data_valid         (data_rcg_valid),
    .led                (led[4:0]),
    .keys               (~keys[4:0])
);
wire [23:0]  front_show_data;
wire front_de;

front_show #(
    .front_xstart(16'd200),
    .front_ystart(16'd70),
    .front_high(8'd40),
    .front_width(8'd40)
)
u_string_show(
// HDMI_in
//    . pixclk_in(pixclk_in),                            
    . vs_in(vs_in), 
    . hs_in(hs_in), 
    . de_in(de_in),
//    . r_in(r_in), 
//    . g_in(g_in), 
//    . b_in(b_in),  
    . led (led[3:0]),  
//    .pixel_x       (pixel_xpos),
//    .pixel_y       (pixel_ypos),
    .front_colour  (WHITE),
    .back_colour   ({b_in,g_in,r_in}),
    .default_colour({b_in,g_in,r_in}),
    .pixel_clk     (pixclk_in),
    .front_de      (front_de),
    .pixel_data_out (front_show_data)
    );


assign led[6:5]=2'd0;

round_signed #(32,16,10) ifftround_re(.in(xk_axi4s_data_tdata[31:0]),  .out(ifft_data_re));
round_signed #(32,16,10) ifftround_im(.in(xk_axi4s_data_tdata[63:32]), .out(ifft_data_im));

RAM_1 RAM_1 (
  .wr_data                  ({ifft_data_im,ifft_data_re}),    // input [31:0]
  .addr                     (ram_addr       ),          // input [9:0]
  .clk                      (clk_100M           ),            // input
  .wr_en                    (xk_axi4s_data_tvalid),        // input
  .rst                      (~adc_dac_int       ),            // input
  .rd_data                  (tdata_fifo         )     // output [31:0]
);

assign ram_addr = xk_axi4s_data_tvalid ? xk_axi4s_data_tuser[9:0] : read_addr;

algorithm algorithm (
    .clk                    (clk_100M),
    .rst_n                  (adc_dac_int),
    .enable                 (fft_stored),
    .ram_addr               (read_addr),
    .ram_data               (tdata_fifo),
    .freq_data              (freq_data),
    .freq_valid             (freq_valid),
    .freq_tlast             (freq_last),
    .girl2boy               (girl2boy),
    .boy2girl               (boy2girl),
    .separate1              (separate1),
    .separate2              (separate2),
    .denoise                (denoise),
    .debug                  (debug)
);

echo_des echo_des(
    .clk                    (es0_dsclk),
    .rst_n                  (adc_dac_int),
    .enable                 (speaker_ctrl_d1 == DECHO),
    .echo_data              (ldata),
    .exp_data               (rdata),
    .valid                  (rx_r_vld),
    .data_out               (decho_data)
); 


ubus_top ubus(
    .clk48m                 (sys_clk),
    .reset_n                (adc_dac_int),
    .rx                     (uart_rx),
    .tx                     (uart_tx),
    .girl2boy               (girl2boy),
    .boy2girl               (boy2girl),
    .denoise                (denoise),
    .separate1              (separate1),
    .separate2              (separate2),
    .nouput                 (nouput),
    .speaker_ctrl           (speaker_ctrl),
    .switch_display         (switch_display),
    .test_eth               (test_eth)
);
//////////////////////////////HDMI LOOP//////////////////////////////////////////////////
ms72xx_ctl ms72xx_ctl(
        .clk         (  cfg_clk    ), //input       clk,
        .rst_n       (  rstn_out_hdmi   ), //input       rstn,
                                
        .init_over   (  init_over  ), //output      init_over,
        .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
        .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
        .iic_scl     (  iic_scl    ), //output      iic_scl,
        .iic_sda     (  iic_sda    )  //inout       iic_sda
    );


reg [15:0]  rstn_1ms_hdmi       ;

    always @(posedge cfg_clk)
    begin
    	if(!locked)
    	    rstn_1ms_hdmi <= 16'd0;
    	else
    	begin
    		if(rstn_1ms_hdmi == 16'h2710)
    		    rstn_1ms_hdmi <= rstn_1ms_hdmi;
    		else
    		    rstn_1ms_hdmi <= rstn_1ms_hdmi + 1'b1;
    	end
    end
    
    assign rstn_out_hdmi = (rstn_1ms_hdmi == 16'h2710);
//////////////////////////////display variation define and switch///////////////////////
wire vs_out_s1,vs_out_s2;
wire hs_out_s1,hs_out_s2;
wire de_out_s1,de_out_s2;
wire [7:0] r_out_s1,r_out_s2;
wire [7:0] g_out_s1,g_out_s2;
wire [7:0] b_out_s1,b_out_s2;
wire pixclk_out_s1,pixclk_out_s2;
reg  switch;
wire ctrl;

    always @(posedge pixclk_out)
    begin
        if (vs_in)begin
            if(ctrl)
            switch <= ~switch_display;//ctrl switch_display
            else
            switch <= switch_display;
                  end
        else
            switch <= switch;
    end

assign vs_out=switch? vs_out_s2 : vs_out_s1;
assign hs_out=switch? hs_out_s2 : hs_out_s1;
assign de_out=switch? de_out_s2 : de_out_s1;
assign r_out =switch? (front_de?front_show_data[7:0]:r_out_s2) : (front_de?front_show_data[7:0]:r_out_s1) ;
assign g_out =switch? (front_de?front_show_data[15:8]:g_out_s2) : (front_de?front_show_data[15:8]:g_out_s1) ;
assign b_out =switch? (front_de?front_show_data[23:16]:b_out_s2) : (front_de?front_show_data[23:16]:b_out_s1) ;
assign pixclk_out=pixclk_out_s1;


//wire edge_ctrl;
//reg  ctrl_d0,ctrl_d1;

//    always @(posedge pixclk_out)
//    begin
//        if(~adc_dac_int)
//         begin     ctrl_d0<=0; ctrl_d1<=0;    end
//        else
//         begin     ctrl_d0<=ctrl; ctrl_d1<=ctrl_d0;    end
//    end

//assign edge_ctrl=ctrl_d0^ctrl_d1;

   key_ctl key_ctl(
       .clk        (  sys_clk  ),//input            clk,
       .key        (  keys[6]  ),//input            key,
                 
       .ctrl       (  ctrl  )//output     [1:0] ctrl
   );
///////////////////////////////spectrum///////////////////////////////////////////////////
spectrum      spectrum_0
(   
// GLOBAL
    . rst_n(adc_dac_int)    ,
    . init_over(1'b1),
// HDMI_in
    . pixclk_in(pixclk_in),                            
    . vs_in(vs_in), 
    . hs_in(hs_in), 
    . de_in(de_in),
    . r_in(r_in), 
    . g_in(g_in), 
    . b_in(b_in),                              
//HDMI OUT
    . pixclk_out(pixclk_out_s1),                            
    . vs_out(vs_out_s1),
    . de_out(de_out_s1),  
    . hs_out(hs_out_s1), 
    . r_out(r_out_s1),  
    . g_out(g_out_s1), 
    . b_out(b_out_s1),
//Stream_ctrler
    . i_axi4s_data_tdata(xk_axi4s_data_tdata) ,
    . i_axi4s_data_tuser(xk_axi4s_data_tuser) , //wrram_addr
    . i_aclk(clk_100M)      , //wrram_clk
    . i_axi4s_data_tvalid(xk_axi4s_data_tvalid), //wrram_valid
    . state(current_state)         //while state==S2(5'b00100);  

);

//////////////////////////////////////////////////////////////////////////spectrogram/////////////////////////////////////////////////
spectrogram      spectrogram_0
(   
// GLOBAL
    . rst_n(adc_dac_int)    ,
    . init_over(1'b1),
// HDMI_in
    . pixclk_in(pixclk_in),                            
    . vs_in(vs_in), 
    . hs_in(hs_in), 
    . de_in(de_in),
    . r_in(r_in), 
    . g_in(g_in), 
    . b_in(b_in),                              
//HDMI OUT
    . pixclk_out(pixclk_out_s2),                            
    . vs_out(vs_out_s2),
    . de_out(de_out_s2),  
    . hs_out(hs_out_s2), 
    . r_out(r_out_s2),  
    . g_out(g_out_s2), 
    . b_out(b_out_s2),
//Stream_ctrler
    . i_axi4s_data_tdata(xk_axi4s_data_tdata) ,
    . i_axi4s_data_tuser(xk_axi4s_data_tuser) , //wrram_addr
    . i_aclk(clk_100M)      , //wrram_clk
    . i_axi4s_data_tvalid(xk_axi4s_data_tvalid), //wrram_valid
    . state(current_state)         //while state==S2(5'b00100);  

);
// assign led[7] = girl2boy;
// assign led[6] = denoise;
// assign led[5] = debug;
// assign led[3:1] = speaker_ctrl_d1;
// assign led[0] = adc_dac_int;
 assign led[7] = led_eth;
//////////////////////////////////////////////////////////////////////////////////////////////////Ethernet
reg [15:0] audio_test_data=0;
wire[15:0] audio_data;


always @(posedge es0_dsclk)
if(!adc_dac_int) begin
    audio_test_data <= 0;
end
else begin
    if(l_lvd_out)
    audio_test_data <= audio_test_data+1 ;
    else 
    audio_test_data <=audio_test_data;
end

assign audio_data=test_eth  ?audio_test_data:tx_ldata_tmp;


`ifdef SIMULATION

`else
 gvrd_test     gvrd_test(
//    .        clk_50m(clk_50M),
    .        led(led_eth),
    .        phy_rstn(phy_rstn),
    .        rstn(locked),
   
    .        rgmii_rxc(rgmii_rxc),
    .        rgmii_rx_ctl(rgmii_rx_ctl),
    .        rgmii_rxd(rgmii_rxd),

    .        audio_dv(l_lvd_out), // l_lvd_out
    .        audio_data(audio_data),//  tx_ldata
    .        audio_clk(es0_dsclk),      
                 
    .        rgmii_txc(rgmii_txc),
    .        rgmii_tx_ctl(rgmii_tx_ctl),
    .        rgmii_txd(rgmii_txd) 
);

`endif



endmodule