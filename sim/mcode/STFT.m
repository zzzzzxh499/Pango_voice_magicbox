% 读取音频文件
[audioIn, fs] = audioread('split.mp3');
audioIn = audioIn(:, 1); % 如果是立体声，取第一个声道

% 设置 STFT 参数
windowLength = 1024;
overlapLength = round(0.75 * windowLength); % 75% 重叠
fftLength = 1024;

% 计算 STFT
[S, F, T] = stft(audioIn, fs, 'Window', hamming(windowLength, 'periodic'), 'OverlapLength', overlapLength, 'FFTLength', fftLength);

% 绘制 STFT 频谱图
figure;
imagesc(T, F, 20*log10(abs(S))); % 将幅度转换为 dB
axis xy;
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('STFT Magnitude Spectrum');

% 绘制 3D 频谱图
figure;
surf(T, F, 20*log10(abs(S)), 'EdgeColor', 'none');
axis xy;
view(0, 90); % 从上方视图
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('STFT Magnitude Spectrum');
