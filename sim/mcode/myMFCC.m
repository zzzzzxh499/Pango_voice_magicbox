% 读取音频文件
[y, fs] = audioread('sample/012.m4a');
y = y(:,1);
y  =y/max(abs(y));
y = y * (2^15-1);
y = fix(y);                                                                 %定点化
y=y(66220:146220-1);
y=[zeros(512,1);y];
N = 1024;                                                                   %fft 点数
overlap = 512;                                                              %加窗重叠
numFilters = 26;                                                            %滤波器个数
R = [300 fs/2];
m = 8;
global a_fix;
log2_lut = log2(1+(0:2^m-1)/2^m);
a_fix = double(fi(log2_lut,1,9,8)*2^m);
%% 内建函数
   
hz2mel = @( hz )( 1127*log(1+hz/700) );     % Hertz to mel warping function
mel2hz = @( mel )( 700*exp(mel/1127)-700 ); % mel to Hertz warping function

% Type III DCT matrix routine (DCT - Discrete Cosine Transform)
dctm = @( N, M )( sqrt(2.0/M) * cos( repmat([0:N-1].',1,M) ...
                                       .* repmat(pi*([1:M]-0.5)/M,N,1) ) );

% Cepstral lifter routine 
ceplifter = @( N, L )( 1+0.5*L*sin(pi*[0:N-1]/L) );
    
%% 预处理
%分帧
ny = length(y);
a = floor(ny/overlap);                                                      %帧数
y = [zeros(overlap,1);y(1:overlap*a)];
                                                              
%加窗
window = hann(N, 'periodic');                                               %使用汉宁窗减少边界效应
window = round(window * 2^15);                                              %定点化fix(15,16)

% 计算 Mel 滤波器组
melFilters = trifbank( numFilters, N/2+1, R, fs, hz2mel, mel2hz );          % size of H is M x K 
melFilters = round(melFilters*2^15);                                        %定点化fix(15,16)

%DCT矩阵
DCT = dctm( 13, 26 ); 
DCT = round(DCT*2^15);                                                      %定点化fix(15,16)

%默认升到普系数为22
lifter = ceplifter( 13, 22 );
lifter = round(lifter*2^10);                                                %定点化fix(15,16)

 %% mfcc计算过程
 feat = zeros(a,13);
 logFBE = zeros(26,a);
 FBE = zeros(26,a);
 X = zeros(1024,a);
for k = 1:a
    segment_start = (k-1) * overlap + 1;
    segment_end = segment_start + N - 1;
    segment = y(segment_start:segment_end);                                 %分帧
    segment_win = fix(segment.*window*2^-15);                               %加窗
    
    X(:,k) = fix(fft(segment_win, N));                                           %傅里叶变换 27bit有符号数                                        
    MAG = fix( (abs(X(:,k)).^2) );                                      %计算功率谱 27*2+1-10=45bit 有符号数（+）+10bit小数
    FBE(:,k) = fix( melFilters * MAG(1:N/2+1) * 2^-13 );                       %应用mel滤波器  （45+15+7=67 bit）-15 = 52bit +12bit小数
    logFBE(:,k) = myloge(FBE(:,k));                                       %取自然对数(用换底公式) 8bit xiaoshu
    Hfcc = fix( DCT * logFBE(:,k) * 2^-15 );                              %DCT变换
    %升倒谱
    feat(k,:) = fix( Hfcc' .* lifter * 2^-10 );                           %mfcc结果
end

%% mfcc参数求取
%接下来求取第二组（一阶差分系数）301x13 ，这也是mfcc参数的第二组参数
 dtfeat=zeros(size(feat));%默认初始化
 for i=3:a-2
     dtfeat(i,:)=-2*feat(i-2,:)-feat(i-1,:)+feat(i+1,:)+2*feat(i+2,:); 
 end

%求取二阶差分系数,mfcc参数的第三组参数
%二阶差分系数就是对前面产生的一阶差分系数dtfeat再次进行操作。
 dttfeat=zeros(size(dtfeat));%默认初始化
 for i=3:a-2
     dttfeat(i,:)=-2*dtfeat(i-2,:)-dtfeat(i-1,:)+dtfeat(i+1,:)+2*dtfeat(i+2,:); 
 end

 %将得到的mfcc的三个参数feat、dtfeat、dttfeat拼接到一起
 %得到最后的mfcc系数301x39
 mfcc_final=[feat,dtfeat,dttfeat];%拼接完成
%% 画图
figure;
imagesc(feat');
title('Custom MFCC');
xlabel('Frame Index');
ylabel('Coefficient Index');

ram_lut = zeros(4,513);
for j=1:26
    i = 2-mod(j,2);
    for k = 1:513
        if melFilters(j,k) ~= 0
            ram_lut(i,k) = melFilters(j,k);
            ram_lut(i+2,k) = ~mod((j-i)/2,2);
        end
    end
end

function result = myloge(a)
        global a_fix;
        a(a==0)=1;
        k = floor(log2(a));
        m = floor((a./ (2.^k) -1) *256)+1;
        result = floor(22713*(k*2^8 + a_fix(m)' - 12*256)/2^15);
end
