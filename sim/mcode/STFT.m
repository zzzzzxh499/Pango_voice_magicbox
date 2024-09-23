% ��ȡ��Ƶ�ļ�
[audioIn, fs] = audioread('split.mp3');
audioIn = audioIn(:, 1); % �������������ȡ��һ������

% ���� STFT ����
windowLength = 1024;
overlapLength = round(0.75 * windowLength); % 75% �ص�
fftLength = 1024;

% ���� STFT
[S, F, T] = stft(audioIn, fs, 'Window', hamming(windowLength, 'periodic'), 'OverlapLength', overlapLength, 'FFTLength', fftLength);

% ���� STFT Ƶ��ͼ
figure;
imagesc(T, F, 20*log10(abs(S))); % ������ת��Ϊ dB
axis xy;
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('STFT Magnitude Spectrum');

% ���� 3D Ƶ��ͼ
figure;
surf(T, F, 20*log10(abs(S)), 'EdgeColor', 'none');
axis xy;
view(0, 90); % ���Ϸ���ͼ
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('STFT Magnitude Spectrum');
