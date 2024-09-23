fid = fopen('div1024.dat','wt');
for i = 1:1023
      fprintf(fid,'%04x\n',round(1/i*2^15));
end

tmp0 = zeros(13,27);
for i=1:26
    for j=1:13
        tmp0(14-j,i+1) = tmp0(14-j,i)+floor(A(i)*DCT(j,i)*2^-10);
    end
end