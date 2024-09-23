% ��ȡ��Ƶ�ļ�
[audioIn, fs] = audioread('boy.mp3');
audioIn = audioIn(:,1);  % �������������ȡ������

% ���ò���
frameSize = 1024;       % ֡��С
hopSize = 512;          % ֡�ƴ�С
window = hann(frameSize, 'periodic'); % ������
pitchFactor = 2.2;  % �����������������Ը���ʵ����Ҫ����

% ���ж�ʱ����Ҷ�任��STFT��
stftMatrix = [];
for i = 1:hopSize:(length(audioIn) - frameSize)
    frame = audioIn(i:i+frameSize-1) .* window;
    frameFFT = fft(frame);
    stftMatrix = [stftMatrix, frameFFT];
end

% �������ߣ�Pitch Shifting��
newStftMatrix = zeros(size(stftMatrix));
[numBins, numFrames] = size(stftMatrix);

LUT_2girl = [1:2:513,10000*ones(1,511),513:2:1023]-1;
LUT_2boy = [0.5:0.5:257,769.5:0.5:1024];
LUT_2boy = round(LUT_2boy)-1;
LUT = zeros(numBins,1);
for i=0:numBins-1
    if(i<=512)%����Ƶ��
        aim_f = round(pitchFactor*i);
        if aim_f>512
            LUT(i+1) = 65535;
        else
            LUT(i+1) = aim_f;
        end
    else
        aim_f = round(pitchFactor*(numBins-i));
        if aim_f>512
            LUT(i+1) = 65535;
        else
            LUT(i+1) = numBins-aim_f;
        end
    end
end


for i = 1:numFrames
    for j = 1:numBins
            newFreqIndex = LUT(j)+1;
        if newFreqIndex <= numBins
            newStftMatrix(newFreqIndex, i) = stftMatrix(j, i);
        end
    end
end

% �������ʱ����Ҷ�任��ISTFT��
outputAudio = zeros((numFrames - 1) * hopSize + frameSize, 1);
for i = 1:numFrames
    frame = ifft(newStftMatrix(:, i), 'symmetric');
    outputAudio((i-1)*hopSize+1 : (i-1)*hopSize+frameSize) = ...
        outputAudio((i-1)*hopSize+1 : (i-1)*hopSize+frameSize) + frame .* window;
end

% ���źͱ��洦������Ƶ
sound(outputAudio, fs);

L = length(audioIn);
f = fs*(0:(L/2))/L;
X = fft(audioIn);

% ���ƴ���ǰ�źŵ�Ƶ��ͼ
figure;
subplot(2,1,1);
plot(f, abs(X(1:L/2+1)));
title('����ǰ�ź�fft');
xlabel('f (Hz)');

L = length(outputAudio);
f = fs*(0:(L/2))/L;
Y = fft(outputAudio);

% ���ƴ�����źŵ�Ƶ��ͼ
subplot(2,1,2);
plot(f, abs(Y(1:L/2+1)));
title('������ź�fft');
xlabel('f (Hz)');

fid = fopen('lut.dat','wt');
fprintf(fid,'%04x\n',LUT);
fclose(fid);

