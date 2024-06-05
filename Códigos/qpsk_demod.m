% DEMODULAÇÃO QPSK (sem a parte do demapper)
function [I, Q] = qpsk_demod(sr, fs, fc, rx)

%% Downconversion
% Retorna o sinal para a banda-base
bb = 0:length(rx)-1;
XI = cos(2*pi*fc*bb/fs);
XQ = sin(2*pi*fc*bb/fs);
uir = rx.*XI;
uqr = rx.*-XQ;

%% LPF (FIR Gaussiano)
% Aqui, o filtro é responsável por eliminar as réplicas indesejáveis
% geradas pela heterodinação, mantendo apenas o espectro centrado em zero
hn = [0.0030 0.0118 0.0390 0.1051 0.2367 0.4445 0.6972 0.9138 ...
      1.0000 0.9138 0.6972 0.4445 0.2367 0.1051 0.0390 0.0118];

k = fs/sr;
lpfI = conv(uir,hn,'same');
lpfQ = conv(uqr,hn,'same');

% figure
% subplot(2,1,1)
% stem(lpfI)
% title('Símbolos I filtrados no demodulador')
% grid on
% subplot(2,1,2)
% stem(lpfQ)
% title('Símbolos Q filtrados no demodulador')
% grid on

%% Downsampling
% Para fazer o downsampling, busca-se o melhor instante de amostragem e faz
% um chaveamento mantendo somente esses instantes

% Por inspeção da variável, o instante ótimo de amostragem é 9, 25, 41, ...
ost = 9;
for n=0:(length(lpfI)/k)-1
    downI(n+1) = lpfI((n*k)+ost);
    downQ(n+1) = lpfQ((n*k)+ost);
end

% figure
% subplot (2,1,1)
% stem(downI)
% title ('Símbolos I após downsampling');
% grid on
% subplot (2,1,2)
% stem(downQ)
% title ('Símbolos Q após downsampling');
% grid on

%% Automatic Gain Control
% Normalização [-1,1] a partir de constante considerando ruído e
% multipercurso
I = downI/max(abs(downI));
Q = downQ/max(abs(downQ));

% figure
% scatter(I,Q)
% grid on

end