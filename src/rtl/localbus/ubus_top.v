module ubus_top (
   input                 clk48m,
   input                 reset_n,
   input 			     rx ,   
   output  			     tx ,
   output  [0:0]         girl2boy,           // GIRL 2 BOY ENABLE
   output  [0:0]         boy2girl,           // BOY 2 GIRL ENABLE
   output  [0:0]         denoise,            // DENOISE ENABLE
   output  [0:0]         separate1,          // eliminate music
   output  [0:0]         separate2,          // eliminate human speaking
   output  [0:0]         nouput,             // mute
   output  [2:0]         speaker_ctrl,       // Audio output switch : IFFT_ONLY = 3'b001, L_ONLY = 3'b010, R_ONLY = 3'b100, DECHO = 3'b011, LOOP : default;
   output  wire          uart_crc_error_n,
   output  wire          ubus_identify,
   output  wire          switch_display,
   output  wire          test_eth
   
);

wire [31:0] ext_para_0;	
wire [31:0] ext_para_1;
wire [31:0] ext_para_2;
wire [31:0] ext_para_3;
wire [31:0] ext_para_4;
wire [31:0] ext_para_5;
wire [31:0]	ext_para_6; 
wire [31:0]	ext_para_7; 
wire [31:0]	ext_para_8; 
wire [31:0]	ext_para_9;
wire [31:0] ext_para_a;
wire [31:0] ext_para_b;
wire [31:0] ext_para_c;
wire [31:0] ext_para_d;
wire [31:0] ext_para_e; 

local_bus_slve_cis u_local_bus_slve_cis(
               
        .lb_clk        ( clk48m           	) //input              
       ,.lb_reset_n    ( reset_n          	) //input              
       ,.rx            ( rx               	) //input 			   
       ,.tx            ( tx               	) //output  		   
       ,.lb_crc_error_n( uart_crc_error_n 	) //output reg         
       ,.ubus_identify ( ubus_identify    	) //output reg
           
       ,.nd2reg_0      (ext_para_6			) //input   [31:0]     
       ,.nd2reg_1      (ext_para_9        	) //input   [31:0]     
       ,.nd2reg_2      (ext_para_b			) //input   [31:0]     
       ,.nd2reg_3      (ext_para_c			) //input   [31:0]     
       ,.nd2reg_4      (ext_para_e         	) //input   [31:0]     
       ,.nd2reg_5      (              		) //input   [31:0]     
       ,.nd2reg_6      ( 					) //input   [31:0]     
       ,.nd2reg_7      ( 					) //input   [31:0]     

       ,.reg2nd_0      (ext_para_0			) //output reg [31:0]  
       ,.reg2nd_1      (ext_para_1			) //output reg [31:0]  
       ,.reg2nd_2      (ext_para_2    		) //output reg [31:0]  
       ,.reg2nd_3      (ext_para_3  		) //output reg [31:0]  
       ,.reg2nd_4      (ext_para_4  		) //output reg [31:0]  
       ,.reg2nd_5      (ext_para_5  		) //output reg [31:0]  
       ,.reg2nd_6      (  					) //output reg [31:0]  
       ,.reg2nd_7      (ext_para_7  		) //output reg [31:0]  
       ,.reg2nd_8      (  					) //output reg [31:0]  
       ,.reg2nd_9      (			  		) //output reg [31:0]  
       ,.reg2nd_10     (ext_para_a          ) //output reg [31:0]  
       ,.reg2nd_11     (  					) //output reg [31:0]  
       ,.reg2nd_12     (  					) //output reg [31:0]  
       ,.reg2nd_13     (ext_para_d  		) //output reg [31:0]  
       ,.reg2nd_14     (        		    ) //output reg [31:0]  
       ,.reg2nd_15     (  					) //output reg [31:0]  

);

assign boy2girl       = ext_para_0[0];
assign denoise        = ext_para_0[1];
assign girl2boy       = ext_para_0[2];
assign separate1      = ext_para_0[3];
assign separate2      = ext_para_0[4];
assign speaker_ctrl   = ext_para_1[2:0];
assign test_eth       = ext_para_1[3];
assign switch_display = ext_para_3[0];
assign nouput         = ext_para_2[0];
endmodule
