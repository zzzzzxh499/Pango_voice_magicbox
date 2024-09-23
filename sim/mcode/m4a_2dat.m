[y, fs] = audioread('sample/012.m4a');
y = y(:,1);
y  =y/max(abs(y));
y = y * (2^15-1);
y = fix(y);
y=y(66220:146220-1);
m = length(y);
m = 2^ceil(log2(m));
fid=fopen('sound_data.dat','wt');
plot(y);
for i=1:m
    if(i>length(y))
        fprintf(fid,'0000\n');
    else
        if y(i)<0
            fprintf(fid,'%04x\n',y(i)+2^16);
        else
            fprintf(fid,'%04x\n',y(i));
        end
    end
end
fclose(fid);
