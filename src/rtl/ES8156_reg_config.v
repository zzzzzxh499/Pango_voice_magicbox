`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////
//ES8156�мĴ��������ó���
 module ES8156_reg_config(     
	input       clk_12M         ,
	input       rstn            ,
	output      reg_conf_done   ,
	output      i2c_sclk        ,
	inout       i2c_sdat
);

     reg [15:0]clock_cnt=0;
     reg [1:0]config_step;	  
     reg [23:0]i2c_data;
     reg [15:0]reg_data;
     reg start;
	 reg reg_conf_done_reg;
     reg clock_i2c=0;
     reg [8:0]reg_index;
	  
     i2c_com u_i2c_com(
         .clock_i2c     (clock_i2c      ),//input clock_i2c;
         .rstn          (rstn           ),//input rstn;
         .ack           (ack            ),//output ack;
         .i2c_data      (i2c_data       ),//input [23:0]i2c_data;
         .start         (start          ),//input start;
         .tr_end        (tr_end         ),//output tr_end;
         .i2c_sclk      (i2c_sclk       ),//output i2c_sclk;
         .i2c_sdat      (i2c_sdat       ) //inout i2c_sdat;
     );

assign reg_conf_done=reg_conf_done_reg;
//����i2c����ʱ��-100khz    
always@(posedge clk_12M)   
begin
   if(clock_cnt<14)
      clock_cnt<=clock_cnt+1'b1;
   else begin
         clock_i2c<=!clock_i2c;
         clock_cnt<=0;
   end
end


////iic�Ĵ������ù��̿���    
always@(posedge clock_i2c)    
begin
   if(!rstn) begin
       config_step<=0;
       start<=0;
       reg_index<=0;
       reg_conf_done_reg<=0;
   end
   else begin
      if(reg_conf_done_reg==1'b0) begin          //�����ʼ��δ���
			  if(reg_index<=26) begin               //���üĴ���
					 case(config_step)
					 0:begin
						i2c_data<={8'h12,reg_data};       //IIC Device address is 0x12   
						start<=1;                         //i2cд��ʼ
						config_step<=1;                  
					 end
					 1:begin
						if(tr_end) begin                  //i2cд����               					
							 start<=0;
							 config_step<=2;
						end
					 end
					 2:begin
						  reg_index<=reg_index+1'b1;       //������һ���Ĵ���
						  config_step<=0;
					 end
					 endcase
				end
			 else 
				reg_conf_done_reg<=1'b1;                //�Ĵ�����ʼ�����
      end
   end
 end
			
////iic��Ҫ���õļĴ���ֵ  			
always@(reg_index)   
 begin
    case(reg_index)
	 0  :reg_data    <=16'h1000 ;// :V1000@//Version  2023.5.17������·��Ĵ����б�
	 1  :reg_data    <=16'h003C ;// :w003C@
	 2  :reg_data    <=16'h0005 ;// :D0005@
	 3  :reg_data    <=16'h001C ;// :w001C@
	 4  :reg_data    <=16'h0205 ;// :w0205@
	 5  :reg_data    <=16'h0301 ;// :w0301@
	 6  :reg_data    <=16'h0400 ;// :w0400@
	 7  :reg_data    <=16'h0508 ;// :w0508@
	 8  :reg_data    <=16'h0600 ;// :w0600@
	 9  :reg_data    <=16'h0833 ;// :w0833@
	 10 :reg_data    <=16'h1300 ;// :w1300@
	 11 :reg_data    <=16'h202A ;// :w202A@
	 12 :reg_data    <=16'h213C ;// :w213C@
	 13 :reg_data    <=16'h2202 ;// :w2202@
	 14 :reg_data    <=16'h2407 ;// :w2407@
	 15 :reg_data    <=16'h233A ;// :w233A@
	 16 :reg_data    <=16'h0A01 ;// :w0A01@
	 17 :reg_data    <=16'h0B01 ;// :w0B01@
	 18 :reg_data    <=16'h14BD ;// :w14BD@
	 19 :reg_data    <=16'h0121 ;// :w0121@
	 20 :reg_data    <=16'h0D14 ;// :w0D14@
	 21 :reg_data    <=16'h1800 ;// :w1800@
	 22 :reg_data    <=16'h083F ;// :w083F@ 
     23 :reg_data    <=16'h2520 ;// :w2520@
     24 :reg_data    <=16'h0002 ;// :w0002@
     25 :reg_data    <=16'h0003 ;// :w0003@
     26 :reg_data    <=16'h1130 ;// :w1130@              
	 default:reg_data<=16'hffff ;//        
    endcase      
end	 


endmodule

