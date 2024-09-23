module spectrogram
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
    parameter               RAM_NUM = 140;
    parameter               LEFT_BORDER = 400;
    parameter               TOP_BORDER  = 29 ;
    parameter               HORIZONTAL_LENGTH = 1120 ;
    parameter               VERTICAL_LENGTH   = 1022 ;
    parameter               EACHFFT_WIDTH = 8;
    
// global register/wire 
reg [8:0] rd_addr;
reg       rd_addr_en;
reg [2:0] rd_select_cnt;
reg       rd_addr_select_cnt;
reg [7:0] rd_select;
wire [9:0] rd_color_addr;  // color's lut ram's addr
reg       vout_en;
reg [8:0] color_addr_cnt; // display area's vcnt
reg       hs_in_d0,hs_in_d1;
wire      pos_hs_in;
wire      spectrum_en;

wire [9:0] a_rd_data;
wire [9:0] b_rd_data[RAM_NUM-1:0];
wire [RAM_NUM-1:0]       wr_en    ; 
wire                     wr_en_origin;
wire [9:0] compare_data;

reg tvalid_d0,tvalid_d1;
wire pos_tvalid;
reg [7:0] wr_cnt;

    reg [11:0]        h_count = 'd0;
    reg [11:0]        v_count = 'd0;
////////////////////////////////////////rd_port///////////////////////////////////////////////
always @(posedge pixclk_out)
    if(~rst_n)begin 
    hs_in_d0 <= 'd0;
    hs_in_d1 <= 'd0;
    end
else          begin  
    hs_in_d0 <= hs_in;
    hs_in_d1 <= hs_in_d0;
    end

assign pos_hs_in=~hs_in_d1&hs_in_d0;

always @(posedge pixclk_out)
if(~rst_n) rd_addr <= 'd0;
else rd_addr <= 511-color_addr_cnt;

always @(posedge pixclk_out)
if(~rst_n) rd_addr_select_cnt <= 'd0;
else begin 
    if(vout_en&pos_hs_in)
  rd_addr_select_cnt <= ~rd_addr_select_cnt;
  else rd_addr_select_cnt <= rd_addr_select_cnt;
     end

always @(posedge pixclk_out)
if(~rst_n) color_addr_cnt <= 'd0;
else begin
  if(vout_en)begin 
    if(pos_hs_in&rd_addr_select_cnt)
         color_addr_cnt <= color_addr_cnt + 1'b1;
    else color_addr_cnt <= color_addr_cnt;
             end
  else   color_addr_cnt <= 0;  
      end

always @(posedge pixclk_out)
if(~rst_n) rd_select_cnt <= 'd0;
else if(de_in&rd_addr_en)
  begin   
  if(rd_select_cnt>=EACHFFT_WIDTH-1)
  rd_select_cnt <= 0;
  else
  rd_select_cnt <= rd_select_cnt + 1'b1;
  end
else rd_select_cnt <= 'd0;

always @(posedge pixclk_out)
if(~rst_n) rd_select <= 'd0;
else if(rd_addr_en) begin
          if(de_in&(rd_select_cnt==EACHFFT_WIDTH-1)) 
              begin   
              if(rd_select>=RAM_NUM-1)
              rd_select <= 0;
              else
              rd_select <= rd_select + 1'b1;
              end 
          else 
              rd_select <= rd_select;  
                    end
else rd_select <=wr_cnt ;


assign rd_color_addr=b_rd_data[rd_select];
//genvar k;
//always @(posedge i_aclk)
//if(~rst_n)  rd_color_addr <= 'd0;
//else 
//  case(rd_select)  
//  for(k=0;k<RAM_NUM;k++) begin    
//  k : rd_color_addr <= b_rd_data[k];
//  end
//  default : rd_color_addr <= 'd0;
//  endcase
  

//////////////////////////////////////////boundry en///////////////////////////////////////////
always @(posedge pixclk_out)
if(~rst_n) rd_addr_en <= 'd0;
else if(  (h_count>=LEFT_BORDER-1) &  (h_count<=LEFT_BORDER+HORIZONTAL_LENGTH-1-1)    ) 
  rd_addr_en <= 1'b1;
else rd_addr_en <= 'd0;  

always @(posedge pixclk_out)
if(~rst_n) vout_en <= 'd0;
else if(  (v_count>=TOP_BORDER-1) &  (v_count<=TOP_BORDER+VERTICAL_LENGTH-1)    ) 
  vout_en <= 1'b1;
else vout_en <= 'd0;  

//assign   spectrum_en= v_count>= (1023-b_rd_data+28)   ?  1'b1 :  1'b0  ;
///////////////////////////////////////////////////////BRAM////////////////////////////////////////////////////


//////////wr_en
reg wr_en_origin_d0,wr_en_origin_d1,wr_en_origin_d2;
reg [8:0]i_axi4s_data_tuser_d0,i_axi4s_data_tuser_d1,i_axi4s_data_tuser_d2;

always @(posedge i_aclk)
    if(~rst_n)begin 
    tvalid_d0 <= 'd0;
    tvalid_d1 <= 'd0;
    end
else          begin  
    tvalid_d0 <= i_axi4s_data_tvalid&(state==5'b00100);
    tvalid_d1 <= tvalid_d0;
    end

assign pos_tvalid=~tvalid_d1&tvalid_d0;  

assign wr_en_origin=i_axi4s_data_tvalid&(state==5'b00100)&(i_axi4s_data_tuser<=511);
//////////////////delay
always @(posedge i_aclk)
    if(~rst_n)begin 
    wr_en_origin_d0 <= 'd0;
    wr_en_origin_d1 <= 'd0;
    wr_en_origin_d2 <= 'd0;
    end
else          begin  
    wr_en_origin_d0 <= wr_en_origin;
    wr_en_origin_d1 <= wr_en_origin_d0;
    wr_en_origin_d2 <= wr_en_origin_d1;
    end

always @(posedge i_aclk)
    if(~rst_n)begin 
    i_axi4s_data_tuser_d0 <= 'd0;
    i_axi4s_data_tuser_d1 <= 'd0;
    i_axi4s_data_tuser_d2 <= 'd0;
    end
else          begin  
    i_axi4s_data_tuser_d0 <= i_axi4s_data_tuser;
    i_axi4s_data_tuser_d1 <= i_axi4s_data_tuser_d2;
    i_axi4s_data_tuser_d2 <= i_axi4s_data_tuser_d1;
    end

always @(posedge i_aclk)
    if(~rst_n)begin 
    wr_cnt <= 'd0;
    end
else     begin 
    if(pos_tvalid) begin
      if(wr_cnt>=RAM_NUM-1)
      wr_cnt <= 'd0;
      else
      wr_cnt <= wr_cnt+1;    
    end 
    else           begin
      wr_cnt <= wr_cnt;
    end           
         end

reg[RAM_NUM-1:0] wr_select;        
always @(posedge i_aclk)
    if(~rst_n)begin 
          wr_select<=0;
      end    
else          begin  
          wr_select<=140'b1<<wr_cnt;
    end

genvar j ;
for(j=0;j<RAM_NUM;j=j+1) begin
assign wr_en[j]=wr_select[j]?wr_en_origin_d2:1'b0;
end

wire [15:0] fft_odata_real = i_axi4s_data_tdata[26] ? ~i_axi4s_data_tdata[25:0] + 1'b1 : i_axi4s_data_tdata[25:0];
wire [15:0] fft_odata_imag = i_axi4s_data_tdata[58] ? ~i_axi4s_data_tdata[57-:26]+ 1'b1 : i_axi4s_data_tdata[57-:26];

genvar i;
generate 
for(i=0;i<RAM_NUM;i=i+1)begin:ram_i
DRAM_spectrogram DRAM_spectrogram (
  .a_addr(i_axi4s_data_tuser[8:0]), // input [8:0]
  .a_wr_data(fft_odata_real[14-:10]),    // input [9:0]
  .a_rd_data(),    // output [9:0]
  .a_wr_en(wr_en[i]),        // input
  .a_clk(i_aclk),            // input
  .a_rst(~rst_n),            // input
  .b_addr(rd_addr),          // input [8:0]
  .b_wr_data(10'd0),    // input [9:0]
  .b_rd_data(b_rd_data[i]),    // output [9:0]
  .b_wr_en(1'b0),        // input
  .b_clk(pixclk_out),            // input
  .b_rst(~rst_n)             // input
);
  end
endgenerate  

// RGB RAM
wire[7:0] R_data;
wire[7:0] G_data;
wire[7:0] B_data;

R_LUT R_LUT (
  .addr(rd_color_addr),          // input [9:0]
  .clk(pixclk_out),            // input
  .rst(~rst_n),            // input
  .rd_data(R_data)     // output [7:0]
);

G_LUT G_LUT (
  .addr(rd_color_addr),          // input [9:0]
  .clk(pixclk_out),            // input
  .rst(~rst_n),            // input
  .rd_data(G_data)     // output [7:0]
);

B_LUT B_LUT (
  .addr(rd_color_addr),          // input [9:0]
  .clk(pixclk_out),            // input
  .rst(~rst_n),            // input
  .rd_data(B_data)     // output [7:0]
);

/////////////////////////////////////////////// HDMI///////////////////////////////////////////////////////////// 

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
            r_out        <=  ~(rd_addr_en&vout_en)? r_in  : R_data       ;
            g_out        <=  ~(rd_addr_en&vout_en)? g_in  : G_data       ;
            b_out        <=  ~(rd_addr_en&vout_en)? b_in  : B_data       ;
            //r_out        <=   r_in         ;
            //g_out        <=   g_in         ;
            //b_out        <=   b_in         ;
        end
    end

// FFT IP



endmodule


