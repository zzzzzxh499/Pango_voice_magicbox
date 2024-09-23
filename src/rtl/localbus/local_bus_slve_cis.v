`timescale 1ns/1ps

module local_bus_slve_cis (
               
input                          lb_clk,
input                          lb_reset_n,
input 			               rx ,
output  			           tx ,
output reg                     lb_crc_error_n,
output reg                     ubus_identify,

//----------------------------------REG-----------------------------

input   [31:0]                 nd2reg_0 , 
input   [31:0]                 nd2reg_1 ,
input   [31:0]                 nd2reg_2 ,
input   [31:0]                 nd2reg_3 ,
input   [31:0]                 nd2reg_4 ,
input   [31:0]                 nd2reg_5 ,
input   [31:0]                 nd2reg_6 ,
input   [31:0]                 nd2reg_7 ,

output reg [31:0]              reg2nd_0  ,
output reg [31:0]              reg2nd_1  ,
output reg [31:0]              reg2nd_2  ,
output reg [31:0]              reg2nd_3  ,
output reg [31:0]              reg2nd_4  ,
output reg [31:0]              reg2nd_5  ,
output reg [31:0]              reg2nd_6  ,
output reg [31:0]              reg2nd_7  , 
output reg [31:0]              reg2nd_8  , 
output reg [31:0]              reg2nd_9  , 
output reg [31:0]              reg2nd_10 , 
output reg [31:0]              reg2nd_11 , 
output reg [31:0]              reg2nd_12 , 
output reg [31:0]              reg2nd_13 , 
output reg [31:0]              reg2nd_14 , 
output reg [31:0]              reg2nd_15 
              

);

   
//Regist tab -----------------------------------------------------------------------------------------------------

reg[31:0]                      reg0   ;                        
reg[31:0]                      reg1   ;                        
reg[31:0]                      reg2   ;                        
reg[31:0]                      reg3   ;                        
reg[31:0]                      reg4   ;                        
reg[31:0]                      reg5   ;                        
reg[31:0]                      reg6   ;                        
reg[31:0]                      reg7   ;                        
reg[31:0]                      reg8   ;                        
reg[31:0]                      reg9   ;                        
reg[31:0]                      reg10  ;                        
reg[31:0]                      reg11  ;                        
reg[31:0]                      reg12  ;                        
reg[31:0]                      reg13  ;                        
reg[31:0]                      reg14  ;                        
reg[31:0]                      reg15  ;                        


//-------------------------------------------------------------------------------

initial
     begin
        reg0    <= 32'h00000000;
        reg1    <= 32'h00000008;
        reg2    <= 32'h00000000;
        reg3    <= 32'h00000000;
        reg4    <= 32'h00004104;
        reg5    <= 32'h017a1038;
        reg6    <= 32'h00000002;
        reg7    <= 32'h00000000;
        reg8    <= 32'h017a00c9;
        reg9    <= 32'h00000000;
        reg10   <= 32'h01e0781e;
        reg11   <= 32'hffffffff;
        reg12   <= 32'h00000355;
        reg13   <= 32'h00000000;
        reg14   <= 32'h00000000;
        reg15   <= 32'h00010002;
     end





   always @ (*) begin

      reg2nd_0        = reg0  ;
      reg2nd_1        = reg1  ;
      reg2nd_2        = reg2  ;
      reg2nd_3        = reg3  ;
      reg2nd_4        = reg4  ;
      reg2nd_5        = reg5  ;
      reg2nd_6        = reg6  ;
      reg2nd_7        = reg7  ;
      reg2nd_8        = reg8  ;
      reg2nd_9        = reg9  ;
      reg2nd_10       = reg10 ;
      reg2nd_11       = reg11 ;
      reg2nd_12       = reg12 ;
      reg2nd_13       = reg13 ;
      reg2nd_14       = reg14 ;
      reg2nd_15       = reg15 ;

   end



endmodule
