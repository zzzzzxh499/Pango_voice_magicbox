module spectrum
(   
// GLOBAL
    input             rst_n    ,
    input             init_over,
// HDMI_in
    input             pixclk_in,                            
    input             vs_in, 
    input             hs_in, 
    input             de_in,
    input     [7:0]   r_in, 
    input     [7:0]   g_in, 
    input     [7:0]   b_in,                              
//HDMI OUT
    output               pixclk_out,                            
    output reg           vs_out,
    output reg           de_out,  
    output reg           hs_out, 
    output reg    [7:0]  r_out,  
    output reg    [7:0]  g_out, 
    output reg    [7:0]  b_out,
//Stream_ctrler
    input [63:0]        i_axi4s_data_tdata ,
    input [9:0]         i_axi4s_data_tuser , //wrram_addr
    input               i_aclk      , //wrram_clk
    input               i_axi4s_data_tvalid, //wrram_valid
    input [4:0]         state         //while state==S2(5'b00100);
//  output port
//    output              spectrum_en       

);
// parameter
    parameter               H_TOTAL = 12'd1920;
    parameter               V_TOTAL = 12'd1080;
// global register/wire 
reg [9:0] rd_addr;
reg       rd_addr_en;
reg       vout_en;
wire      spectrum_en;

always @(posedge pixclk_out)
if(~rst_n) rd_addr <= 'd0;
else if(de_in&rd_addr_en) 
  rd_addr <= rd_addr + 1'b1;
else rd_addr <= 'd0;

always @(posedge pixclk_out)
if(~rst_n) rd_addr_en <= 'd0;
else if(  (h_count>=448-1) &  (h_count<=447+1024-1)    ) 
  rd_addr_en <= 1'b1;
else rd_addr_en <= 'd0;  

always @(posedge pixclk_out)
if(~rst_n) vout_en <= 'd0;
else if(  (v_count>=28-1) &  (v_count<=1080-29)    ) 
  vout_en <= 1'b1;
else vout_en <= 'd0;  

assign   spectrum_en= v_count>= (1023-b_rd_data+28)   ?  1'b1 :  1'b0  ;
///////////////////////////////////////////////////////BRAM////////////////////////////////////////////////////
wire [9:0] a_rd_data;
wire [9:0] b_rd_data;
wire        wr_en    ; 
wire [9:0] compare_data;


assign wr_en=i_axi4s_data_tvalid&(state==5'b00100);

wire [15:0] fft_odata_real = i_axi4s_data_tdata[26] ? ~i_axi4s_data_tdata[25:0] + 1'b1 : i_axi4s_data_tdata[25:0];
wire [15:0] fft_odata_imag = i_axi4s_data_tdata[58] ? ~i_axi4s_data_tdata[57-:26]+ 1'b1 : i_axi4s_data_tdata[57-:26];

DPRAM FFT_ram (
  .a_addr(i_axi4s_data_tuser),          // input [9:0]
  .a_wr_data(fft_odata_real[15-:10]),    // input [9:0]
  .a_rd_data(a_rd_data),    // output [9:0]
  .a_wr_en(wr_en),        // input
  .a_clk(i_aclk),            // input
  .a_rst(~rst_n),            // input
  .b_addr(rd_addr),          // input [9:0]
  .b_wr_data(10'd0),    // input [9:0]
  .b_rd_data(b_rd_data),    // output [9:0]
  .b_wr_en(1'b0),        // input
  .b_clk(pixclk_out),            // input
  .b_rst(~rst_n)             // input
);

/////////////////////////////////////////////// HDMI///////////////////////////////////////////////////////////// 
    reg [11:0]        h_count = 'd0;
    reg [11:0]        v_count = 'd0;
   /* horizontal counter */
    always @(posedge pixclk_out)
    begin
        if (vs_in)
//        if (!rst_n|vs_in)
            h_count <= 'd0;
        else
        begin
            if ( (h_count < H_TOTAL - 1)&de_in   )
                h_count <= h_count + 1;
            else
                h_count <= 'd0;
        end
    end
    
    /* vertical counter */
    always @(posedge pixclk_out)
    begin
        if (vs_in)
//        if (!rst_n|vs_in)
            v_count <=  'd0;
        else
//        if (vs_in)
//            v_count <=  'd0;
//        else
        if (h_count == H_TOTAL - 1)
        begin
            if (v_count == V_TOTAL - 1)
                v_count <= 'd0;
            else
                v_count <= v_count + 1;
        end
    end
assign pixclk_out   =  pixclk_in    ;


    always  @(posedge pixclk_out)begin
        if(!init_over)begin
    	    vs_out       <=  1'b0        ;
            hs_out       <=  1'b0        ;
            de_out       <=  1'b0        ;
            r_out        <=  8'b0        ;
            g_out        <=  8'b0        ;
            b_out        <=  8'b0        ;
        end
    	    else begin
            vs_out       <=   vs_in        ;
            hs_out       <=   hs_in        ;
            de_out       <=   de_in        ;
            r_out        <=  ~(spectrum_en&rd_addr_en&vout_en)? r_in  : 8'd255       ;
            g_out        <=  ~(spectrum_en&rd_addr_en&vout_en)? g_in  : 8'd255       ;
            b_out        <=  ~(spectrum_en&rd_addr_en&vout_en)? b_in  : 8'd255       ;
            //r_out        <=   r_in         ;
            //g_out        <=   g_in         ;
            //b_out        <=   b_in         ;
        end
    end

// FFT IP



endmodule