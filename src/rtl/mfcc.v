module mfcc_u (
    clk,
    rst_n,
    fft_valid,
    fft_data,
    mfcc,
    mfcc_valid
);
input clk;
input rst_n;
input fft_valid;
input [63:0] fft_data;
output signed [15:0] mfcc;
output mfcc_valid;

parameter N = 13;
parameter M = 26;


wire signed [26:0] fft_imag = fft_data[58-:27];
wire signed [26:0] fft_real = fft_data[00+:27];
wire [54:0] fft_sqrs;// abs(fft)^2 fix(55,10) 10bit xiaoshu
reg [6:0] valid_d;
wire [63:0] fbe;
wire fbe_valid;
reg [8:0] fbe_valid_d;
wire signed [15:0] log_fbe;
wire signed [15:0] mfcc_tmp;
wire mfcc_tmp_valid;
wire [3:0] mfcc_tmp_index;


always @(posedge clk)
if(~rst_n) valid_d <= 7'd0;
else valid_d <= {valid_d[5:0],fft_valid};

always @(posedge clk)
if(~rst_n) fbe_valid_d <= 9'd0;
else fbe_valid_d <= {fbe_valid_d[7:0],fbe_valid};


Squares Squares(clk,rst_n,fft_imag,fft_real,fft_sqrs);// abs(fft)^2 delay 4 10bit xiaoshu

filterbank filterbank(clk,rst_n,valid_d[2],fft_sqrs,fbe,fbe_valid); // fix( melFilters * MAG(1:N/2+1) * 2^-13 ); 12bit xiaoshu

logE logE(clk,rst_n,fbe,log_fbe);//delay 9  input fix(64,12) output fix(16,8)

DCT DCT(clk,rst_n,log_fbe,fbe_valid_d[8],mfcc_tmp,mfcc_tmp_valid,mfcc_tmp_index);

lifter lifter(clk,rst_n,mfcc_tmp,mfcc_tmp_valid,mfcc_tmp_index,mfcc,mfcc_valid);

endmodule