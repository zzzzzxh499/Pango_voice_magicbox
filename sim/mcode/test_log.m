m = 8;
global a_fix;
log2_lut = log2(1+(0:2^m-1)/2^m);
a_fix = double(fi(log2_lut,1,9,8)*2^m);
% 
% N = 0:65536;
% plot(N/2^12,myloge(N)/256)
% hold on
% plot(N/2^12,log(N/2^12))

x  = myloge(46710345754721);


function result = myloge(a)
        global a_fix;
        a(a==0)=1;
        k = floor(log2(a));
        m = floor((a./ (2.^k) -1) *256)+1;
        result = floor(22713*(k*2^8 + a_fix(m) - 12*256)/2^15);
end
