% ��ȡ��Ƶ�ļ�
[y, fs] = audioread('sample/012.m4a');
y = y(:,1);
y  =y/max(abs(y));
y = y * (2^15-1);
y = fix(y);                                                                 %���㻯
y=y(66220:146220-1);
y=[zeros(512,1);y];
N = 1024;                                                                   %fft ����
overlap = 512;                                                              %�Ӵ��ص�
numFilters = 26;                                                            %�˲�������
R = [300 fs/2];
m = 8;
global a_fix;
log2_lut = log2(1+(0:2^m-1)/2^m);
a_fix = double(fi(log2_lut,1,9,8)*2^m);
%% �ڽ�����
   
hz2mel = @( hz )( 1127*log(1+hz/700) );     % Hertz to mel warping function
mel2hz = @( mel )( 700*exp(mel/1127)-700 ); % mel to Hertz warping function

% Type III DCT matrix routine (DCT - Discrete Cosine Transform)
dctm = @( N, M )( sqrt(2.0/M) * cos( repmat([0:N-1].',1,M) ...
                                       .* repmat(pi*([1:M]-0.5)/M,N,1) ) );

% Cepstral lifter routine 
ceplifter = @( N, L )( 1+0.5*L*sin(pi*[0:N-1]/L) );
    
%% Ԥ����
%��֡
ny = length(y);
a = floor(ny/overlap);                                                      %֡��
y = [zeros(overlap,1);y(1:overlap*a)];
                                                              
%�Ӵ�
window = hann(N, 'periodic');                                               %ʹ�ú��������ٱ߽�ЧӦ
window = round(window * 2^15);                                              %���㻯fix(15,16)

% ���� Mel �˲�����
melFilters = trifbank( numFilters, N/2+1, R, fs, hz2mel, mel2hz );          % size of H is M x K 
melFilters = round(melFilters*2^15);                                        %���㻯fix(15,16)

%DCT����
DCT = dctm( 13, 26 ); 
DCT = round(DCT*2^15);                                                      %���㻯fix(15,16)

%Ĭ��������ϵ��Ϊ22
lifter = ceplifter( 13, 22 );
lifter = round(lifter*2^10);                                                %���㻯fix(15,16)

 %% mfcc�������
 feat = zeros(a,13);
 logFBE = zeros(26,a);
 FBE = zeros(26,a);
 X = zeros(1024,a);
for k = 1:a
    segment_start = (k-1) * overlap + 1;
    segment_end = segment_start + N - 1;
    segment = y(segment_start:segment_end);                                 %��֡
    segment_win = fix(segment.*window*2^-15);                               %�Ӵ�
    
    X(:,k) = fix(fft(segment_win, N));                                           %����Ҷ�任 27bit�з�����                                        
    MAG = fix( (abs(X(:,k)).^2) );                                      %���㹦���� 27*2+1-10=45bit �з�������+��+10bitС��
    FBE(:,k) = fix( melFilters * MAG(1:N/2+1) * 2^-13 );                       %Ӧ��mel�˲���  ��45+15+7=67 bit��-15 = 52bit +12bitС��
    logFBE(:,k) = myloge(FBE(:,k));                                       %ȡ��Ȼ����(�û��׹�ʽ) 8bit xiaoshu
    Hfcc = fix( DCT * logFBE(:,k) * 2^-15 );                              %DCT�任
    %������
    feat(k,:) = fix( Hfcc' .* lifter * 2^-10 );                           %mfcc���
end

%% mfcc������ȡ
%��������ȡ�ڶ��飨һ�ײ��ϵ����301x13 ����Ҳ��mfcc�����ĵڶ������
 dtfeat=zeros(size(feat));%Ĭ�ϳ�ʼ��
 for i=3:a-2
     dtfeat(i,:)=-2*feat(i-2,:)-feat(i-1,:)+feat(i+1,:)+2*feat(i+2,:); 
 end

%��ȡ���ײ��ϵ��,mfcc�����ĵ��������
%���ײ��ϵ�����Ƕ�ǰ�������һ�ײ��ϵ��dtfeat�ٴν��в�����
 dttfeat=zeros(size(dtfeat));%Ĭ�ϳ�ʼ��
 for i=3:a-2
     dttfeat(i,:)=-2*dtfeat(i-2,:)-dtfeat(i-1,:)+dtfeat(i+1,:)+2*dtfeat(i+2,:); 
 end

 %���õ���mfcc����������feat��dtfeat��dttfeatƴ�ӵ�һ��
 %�õ�����mfccϵ��301x39
 mfcc_final=[feat,dtfeat,dttfeat];%ƴ�����
%% ��ͼ
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
