% 读取音频文件
[audioIn, fs] = audioread('boy.mp3');
audioIn = audioIn(:,1);  % 如果是立体声，取单声道

% 设置参数
frameSize = 1024;       % 帧大小
hopSize = 512;          % 帧移大小
window = hann(frameSize, 'periodic'); % 窗函数
pitchFactor = 2.2;  % 音高提升倍数，可以根据实际需要调整

% 进行短时傅里叶变换（STFT）
stftMatrix = [];
for i = 1:hopSize:(length(audioIn) - frameSize)
    frame = audioIn(i:i+frameSize-1) .* window;
    frameFFT = fft(frame);
    stftMatrix = [stftMatrix, frameFFT];
end

% 调整音高（Pitch Shifting）
newStftMatrix = zeros(size(stftMatrix));
[numBins, numFrames] = size(stftMatrix);

LUT_2girl = [1:2:513,10000*ones(1,511),513:2:1023]-1;
LUT_2boy = [0.5:0.5:257,769.5:0.5:1024];
LUT_2boy = round(LUT_2boy)-1;
LUT = zeros(numBins,1);
for i=0:numBins-1
    if(i<=512)%单边频率
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

% 进行逆短时傅里叶变换（ISTFT）
outputAudio = zeros((numFrames - 1) * hopSize + frameSize, 1);
for i = 1:numFrames
    frame = ifft(newStftMatrix(:, i), 'symmetric');
    outputAudio((i-1)*hopSize+1 : (i-1)*hopSize+frameSize) = ...
        outputAudio((i-1)*hopSize+1 : (i-1)*hopSize+frameSize) + frame .* window;
end

% 播放和保存处理后的音频
sound(outputAudio, fs);

L = length(audioIn);
f = fs*(0:(L/2))/L;
X = fft(audioIn);

% 绘制处理前信号的频谱图
figure;
subplot(2,1,1);
plot(f, abs(X(1:L/2+1)));
title('处理前信号fft');
xlabel('f (Hz)');

L = length(outputAudio);
f = fs*(0:(L/2))/L;
Y = fft(outputAudio);

% 绘制处理后信号的频谱图
subplot(2,1,2);
plot(f, abs(Y(1:L/2+1)));
title('处理后信号fft');
xlabel('f (Hz)');

fid = fopen('lut.dat','wt');
fprintf(fid,'%04x\n',LUT);
fclose(fid);

