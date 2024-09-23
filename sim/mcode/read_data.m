a=textread('i_data.dat',"%s");
b=textread('o_data.dat',"%s");
fs=48000;
n=1024;
re_idata = zeros(n,1);
im_idata = zeros(n,1);
re_odata = zeros(n,1);
im_odata = zeros(n,1);
phas1=1024;
phas2=1024;
for ii=1:n
    im_idata(ii)=sbin2dec(a{ii+phas1}(1:16));
    re_idata(ii)=sbin2dec(a{ii+phas1}(17:32));
end
% for ii=1:n
%     im_odata(ii)=sbin2dec(b{ii+phas2}(6:32));
%     re_odata(ii)=sbin2dec(b{ii+phas2}(38:64));
% end
for ii=1:n
    im_odata(ii)=sbin2dec(b{ii+phas2}(6:21));
    re_odata(ii)=sbin2dec(b{ii+phas2}(38:53));
end

% for ii=1:1024
%     re_odata(ii)=sbin2dec(b{ii});
% end
x=linspace(-fs/2,fs/2-1,n);
% fft结果
% figure(1);
% plot(x,re_odata);
% zff=fft(re_idata);
% figure(2);
% plot(x,real(zff));

% aaa = ifft(re_idata+1i*im_idata,1024);
% plot(aaa)
%时域数据
% figure(1);
% plot(re_idata);
% figure(2);
% plot(re_odata);

function deca = sbin2dec(bina)
    blen = length(bina);
    if bina(1) == '1' 
        deca = bin2dec(bina) - 2^blen;
    else
        deca = bin2dec(bina);
    end
end

