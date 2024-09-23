module log2  //delay 3
(
	clk,
	i_data,
	o_data
);
parameter             O_WIDTH_F = 8;   //output 小数位宽
parameter             I_WIDTH = 64;   //input width (固定32bit，不足32bit输入高位补0)    
parameter             O_WIDTH = O_WIDTH_F + $clog2(I_WIDTH);   //output width，O_WIDTH >= O_WIDTH_F + $clog2(I_WIDTH)

input clk;
input [I_WIDTH-1 : 0]  i_data;
output reg [O_WIDTH-1 : 0]  o_data;

localparam PRECISION_W = 8;

reg [I_WIDTH-1 : 0]  r_i_data;
reg [O_WIDTH_F-1:0] log_rom [(2**PRECISION_W)-1:0];
reg [O_WIDTH_F-1:0] fra_data;
reg [PRECISION_W-1:0] fra_index;
reg [$clog2(I_WIDTH)-1:0] int_d,int_d_c0;
initial 
  $readmemh("D:/projects/pango/Pango_magicbox/sim/mcode/log2_f.txt", log_rom, 0, (2**PRECISION_W)-1);

always @(posedge clk) fra_data <= log_rom[fra_index];

always @(posedge clk) r_i_data <= i_data;

always @(posedge clk) int_d_c0 <= int_d;

always @(posedge clk) o_data <= {int_d_c0,fra_data};


always @ (posedge clk) begin
	casez(r_i_data) 
        {{00{1'b0}},1'b1,{(I_WIDTH-01){1'b?}}}: begin int_d <= I_WIDTH - 01; fra_index <=  r_i_data[62 -: PRECISION_W] ; end
        {{01{1'b0}},1'b1,{(I_WIDTH-02){1'b?}}}: begin int_d <= I_WIDTH - 02; fra_index <=  r_i_data[61 -: PRECISION_W] ; end 
        {{02{1'b0}},1'b1,{(I_WIDTH-03){1'b?}}}: begin int_d <= I_WIDTH - 03; fra_index <=  r_i_data[60 -: PRECISION_W] ; end 
        {{03{1'b0}},1'b1,{(I_WIDTH-04){1'b?}}}: begin int_d <= I_WIDTH - 04; fra_index <=  r_i_data[59 -: PRECISION_W] ; end 
        {{04{1'b0}},1'b1,{(I_WIDTH-05){1'b?}}}: begin int_d <= I_WIDTH - 05; fra_index <=  r_i_data[58 -: PRECISION_W] ; end 
        {{05{1'b0}},1'b1,{(I_WIDTH-06){1'b?}}}: begin int_d <= I_WIDTH - 06; fra_index <=  r_i_data[57 -: PRECISION_W] ; end 
        {{06{1'b0}},1'b1,{(I_WIDTH-07){1'b?}}}: begin int_d <= I_WIDTH - 07; fra_index <=  r_i_data[56 -: PRECISION_W] ; end 
        {{07{1'b0}},1'b1,{(I_WIDTH-08){1'b?}}}: begin int_d <= I_WIDTH - 08; fra_index <=  r_i_data[55 -: PRECISION_W] ; end 
        {{08{1'b0}},1'b1,{(I_WIDTH-09){1'b?}}}: begin int_d <= I_WIDTH - 09; fra_index <=  r_i_data[54 -: PRECISION_W] ; end 
        {{09{1'b0}},1'b1,{(I_WIDTH-10){1'b?}}}: begin int_d <= I_WIDTH - 10; fra_index <=  r_i_data[53 -: PRECISION_W] ; end 
        {{10{1'b0}},1'b1,{(I_WIDTH-11){1'b?}}}: begin int_d <= I_WIDTH - 11; fra_index <=  r_i_data[52 -: PRECISION_W] ; end 
        {{11{1'b0}},1'b1,{(I_WIDTH-12){1'b?}}}: begin int_d <= I_WIDTH - 12; fra_index <=  r_i_data[51 -: PRECISION_W] ; end 
        {{12{1'b0}},1'b1,{(I_WIDTH-13){1'b?}}}: begin int_d <= I_WIDTH - 13; fra_index <=  r_i_data[50 -: PRECISION_W] ; end 
        {{13{1'b0}},1'b1,{(I_WIDTH-14){1'b?}}}: begin int_d <= I_WIDTH - 14; fra_index <=  r_i_data[49 -: PRECISION_W] ; end 
        {{14{1'b0}},1'b1,{(I_WIDTH-15){1'b?}}}: begin int_d <= I_WIDTH - 15; fra_index <=  r_i_data[48 -: PRECISION_W] ; end 
        {{15{1'b0}},1'b1,{(I_WIDTH-16){1'b?}}}: begin int_d <= I_WIDTH - 16; fra_index <=  r_i_data[47 -: PRECISION_W] ; end 
        {{16{1'b0}},1'b1,{(I_WIDTH-17){1'b?}}}: begin int_d <= I_WIDTH - 17; fra_index <=  r_i_data[46 -: PRECISION_W] ; end 
        {{17{1'b0}},1'b1,{(I_WIDTH-18){1'b?}}}: begin int_d <= I_WIDTH - 18; fra_index <=  r_i_data[45 -: PRECISION_W] ; end 
        {{18{1'b0}},1'b1,{(I_WIDTH-19){1'b?}}}: begin int_d <= I_WIDTH - 19; fra_index <=  r_i_data[44 -: PRECISION_W] ; end 
        {{19{1'b0}},1'b1,{(I_WIDTH-20){1'b?}}}: begin int_d <= I_WIDTH - 20; fra_index <=  r_i_data[43 -: PRECISION_W] ; end 
        {{20{1'b0}},1'b1,{(I_WIDTH-21){1'b?}}}: begin int_d <= I_WIDTH - 21; fra_index <=  r_i_data[42 -: PRECISION_W] ; end 
        {{21{1'b0}},1'b1,{(I_WIDTH-22){1'b?}}}: begin int_d <= I_WIDTH - 22; fra_index <=  r_i_data[41 -: PRECISION_W] ; end 
        {{22{1'b0}},1'b1,{(I_WIDTH-23){1'b?}}}: begin int_d <= I_WIDTH - 23; fra_index <=  r_i_data[40 -: PRECISION_W] ; end 
        {{23{1'b0}},1'b1,{(I_WIDTH-24){1'b?}}}: begin int_d <= I_WIDTH - 24; fra_index <=  r_i_data[39 -: PRECISION_W] ; end 
        {{24{1'b0}},1'b1,{(I_WIDTH-25){1'b?}}}: begin int_d <= I_WIDTH - 25; fra_index <=  r_i_data[38 -: PRECISION_W] ; end 
        {{25{1'b0}},1'b1,{(I_WIDTH-26){1'b?}}}: begin int_d <= I_WIDTH - 26; fra_index <=  r_i_data[37 -: PRECISION_W] ; end 
        {{26{1'b0}},1'b1,{(I_WIDTH-27){1'b?}}}: begin int_d <= I_WIDTH - 27; fra_index <=  r_i_data[36 -: PRECISION_W] ; end 
        {{27{1'b0}},1'b1,{(I_WIDTH-28){1'b?}}}: begin int_d <= I_WIDTH - 28; fra_index <=  r_i_data[35 -: PRECISION_W] ; end 
        {{28{1'b0}},1'b1,{(I_WIDTH-29){1'b?}}}: begin int_d <= I_WIDTH - 29; fra_index <=  r_i_data[34 -: PRECISION_W] ; end 
        {{29{1'b0}},1'b1,{(I_WIDTH-30){1'b?}}}: begin int_d <= I_WIDTH - 30; fra_index <=  r_i_data[33 -: PRECISION_W] ; end 
        {{30{1'b0}},1'b1,{(I_WIDTH-31){1'b?}}}: begin int_d <= I_WIDTH - 31; fra_index <=  r_i_data[32 -: PRECISION_W] ; end 
        {{31{1'b0}},1'b1,{(I_WIDTH-32){1'b?}}}: begin int_d <= I_WIDTH - 32; fra_index <=  r_i_data[31 -: PRECISION_W] ; end 
        {{32{1'b0}},1'b1,{(I_WIDTH-33){1'b?}}}: begin int_d <= I_WIDTH - 33; fra_index <=  r_i_data[30 -: PRECISION_W] ; end 
        {{33{1'b0}},1'b1,{(I_WIDTH-34){1'b?}}}: begin int_d <= I_WIDTH - 34; fra_index <=  r_i_data[29 -: PRECISION_W] ; end 
        {{34{1'b0}},1'b1,{(I_WIDTH-35){1'b?}}}: begin int_d <= I_WIDTH - 35; fra_index <=  r_i_data[28 -: PRECISION_W] ; end 
        {{35{1'b0}},1'b1,{(I_WIDTH-36){1'b?}}}: begin int_d <= I_WIDTH - 36; fra_index <=  r_i_data[27 -: PRECISION_W] ; end 
        {{36{1'b0}},1'b1,{(I_WIDTH-37){1'b?}}}: begin int_d <= I_WIDTH - 37; fra_index <=  r_i_data[26 -: PRECISION_W] ; end 
        {{37{1'b0}},1'b1,{(I_WIDTH-38){1'b?}}}: begin int_d <= I_WIDTH - 38; fra_index <=  r_i_data[25 -: PRECISION_W] ; end 
        {{38{1'b0}},1'b1,{(I_WIDTH-39){1'b?}}}: begin int_d <= I_WIDTH - 39; fra_index <=  r_i_data[24 -: PRECISION_W] ; end 
        {{39{1'b0}},1'b1,{(I_WIDTH-40){1'b?}}}: begin int_d <= I_WIDTH - 40; fra_index <=  r_i_data[23 -: PRECISION_W] ; end 
        {{40{1'b0}},1'b1,{(I_WIDTH-41){1'b?}}}: begin int_d <= I_WIDTH - 41; fra_index <=  r_i_data[22 -: PRECISION_W] ; end 
        {{41{1'b0}},1'b1,{(I_WIDTH-42){1'b?}}}: begin int_d <= I_WIDTH - 42; fra_index <=  r_i_data[21 -: PRECISION_W] ; end 
        {{42{1'b0}},1'b1,{(I_WIDTH-43){1'b?}}}: begin int_d <= I_WIDTH - 43; fra_index <=  r_i_data[20 -: PRECISION_W] ; end 
        {{43{1'b0}},1'b1,{(I_WIDTH-44){1'b?}}}: begin int_d <= I_WIDTH - 44; fra_index <=  r_i_data[19 -: PRECISION_W] ; end 
        {{44{1'b0}},1'b1,{(I_WIDTH-45){1'b?}}}: begin int_d <= I_WIDTH - 45; fra_index <=  r_i_data[18 -: PRECISION_W] ; end 
        {{45{1'b0}},1'b1,{(I_WIDTH-46){1'b?}}}: begin int_d <= I_WIDTH - 46; fra_index <=  r_i_data[17 -: PRECISION_W] ; end 
        {{46{1'b0}},1'b1,{(I_WIDTH-47){1'b?}}}: begin int_d <= I_WIDTH - 47; fra_index <=  r_i_data[16 -: PRECISION_W] ; end 
        {{47{1'b0}},1'b1,{(I_WIDTH-48){1'b?}}}: begin int_d <= I_WIDTH - 48; fra_index <=  r_i_data[15 -: PRECISION_W] ; end 
        {{48{1'b0}},1'b1,{(I_WIDTH-49){1'b?}}}: begin int_d <= I_WIDTH - 49; fra_index <=  r_i_data[14 -: PRECISION_W] ; end 
        {{49{1'b0}},1'b1,{(I_WIDTH-50){1'b?}}}: begin int_d <= I_WIDTH - 50; fra_index <=  r_i_data[13 -: PRECISION_W] ; end 
        {{50{1'b0}},1'b1,{(I_WIDTH-51){1'b?}}}: begin int_d <= I_WIDTH - 51; fra_index <=  r_i_data[12 -: PRECISION_W] ; end 
        {{51{1'b0}},1'b1,{(I_WIDTH-52){1'b?}}}: begin int_d <= I_WIDTH - 52; fra_index <=  r_i_data[11 -: PRECISION_W] ; end 
        {{52{1'b0}},1'b1,{(I_WIDTH-53){1'b?}}}: begin int_d <= I_WIDTH - 53; fra_index <=  r_i_data[10 -: PRECISION_W] ; end 
        {{53{1'b0}},1'b1,{(I_WIDTH-54){1'b?}}}: begin int_d <= I_WIDTH - 54; fra_index <=  r_i_data[09 -: PRECISION_W] ; end 
        {{54{1'b0}},1'b1,{(I_WIDTH-55){1'b?}}}: begin int_d <= I_WIDTH - 55; fra_index <=  r_i_data[08 -: PRECISION_W] ; end 
        {{55{1'b0}},1'b1,{(I_WIDTH-56){1'b?}}}: begin int_d <= I_WIDTH - 56; fra_index <=  {r_i_data[07 : 00],{(PRECISION_W-08){1'b0}}}; end 
        {{56{1'b0}},1'b1,{(I_WIDTH-57){1'b?}}}: begin int_d <= I_WIDTH - 57; fra_index <=  {r_i_data[06 : 00],{(PRECISION_W-07){1'b0}}}; end 
        {{57{1'b0}},1'b1,{(I_WIDTH-58){1'b?}}}: begin int_d <= I_WIDTH - 58; fra_index <=  {r_i_data[05 : 00],{(PRECISION_W-06){1'b0}}}; end 
        {{58{1'b0}},1'b1,{(I_WIDTH-59){1'b?}}}: begin int_d <= I_WIDTH - 59; fra_index <=  {r_i_data[04 : 00],{(PRECISION_W-05){1'b0}}}; end 
        {{59{1'b0}},1'b1,{(I_WIDTH-60){1'b?}}}: begin int_d <= I_WIDTH - 60; fra_index <=  {r_i_data[03 : 00],{(PRECISION_W-04){1'b0}}}; end 
        {{60{1'b0}},1'b1,{(I_WIDTH-61){1'b?}}}: begin int_d <= I_WIDTH - 61; fra_index <=  {r_i_data[02 : 00],{(PRECISION_W-03){1'b0}}}; end
        {{61{1'b0}},1'b1,{(I_WIDTH-62){1'b?}}}: begin int_d <= I_WIDTH - 62; fra_index <=  {r_i_data[01 : 00],{(PRECISION_W-02){1'b0}}}; end
        {{62{1'b0}},1'b1,{(I_WIDTH-63){1'b?}}}: begin int_d <= I_WIDTH - 63; fra_index <=  {r_i_data[00 : 00],{(PRECISION_W-01){1'b0}}}; end
        {{63{1'b0}},1'b1,{(I_WIDTH-64){1'b?}}}: begin int_d <= I_WIDTH - 64; fra_index <=  {(PRECISION_W-00){1'b0}}; end 
        default:begin int_d <= {$clog2(I_WIDTH){1'b0}}; fra_index <= {PRECISION_W{1'b0}};end
	endcase
end




endmodule