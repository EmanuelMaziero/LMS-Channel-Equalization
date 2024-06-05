% MODULAÇÃO QPSK
function [Iog, Qog, un] = qpsk_mod(bs, sr, fs, fc)

%% BITS -> SÍMBOLOS IQ
% QPSK usa 2 bits por símbolo
Iog = zeros(1,length(bs)/2);
Qog = zeros(1,length(bs)/2);
nn = 1;
% Mapeia bits em símbolos IQ
for n=1:2:length(bs)
    if bs(n:n+1) == [0 0]
        Iog(nn) = +1;
        Qog(nn) = +1;
    elseif bs(n:n+1) == [0 1]
        Iog(nn) = -1;
        Qog(nn) = +1;
    elseif bs(n:n+1) == [1 0]
        Iog(nn) = +1;
        Qog(nn) = -1;
    elseif bs(n:n+1) == [1 1]
        Iog(nn) = -1;
        Qog(nn) = -1;
    end
    nn = nn +1;
end

% scatterplot(Iog+1i*Qog)
% title('Constelação com os símbolos IQ originais')
% grid on

%% Upsampling 
% Aumenta a taxa de amostragem dos sinais IQ
k = fs/sr; % fator de upsampling

upI = [];
upQ = [];
% Adiciona k-1 zeros a cada símbolo
for n=1:length(Iog)
    upI = [upI Iog(n) zeros(1,k-1)];
    upQ = [upQ Qog(n) zeros(1,k-1)];
end

% figure
% subplot(2,1,1)
% stem(upI)
% title('Símbolos I upsampled no modulador')
% xlabel('Amostra')
% ylabel('Amplitude')
% grid on
% subplot(2,1,2)
% stem(upQ)
% title('Símbolos Q upsampled no modulador')
% xlabel('Amostra')
% ylabel('Amplitude')
% grid on

%% LPF (FIR Gaussiano)
% Nesse passo, o filtro FIR LPF Gaussiano busca suavizar transições
% abruptas

% Coeficientes do filtro - função de transferência
hn = [0.0030 0.0118 0.0390 0.1051 0.2367 0.4445 0.6972 0.9138 1.0000 0.9138 0.6972 0.4445 0.2367 0.1051 0.0390 0.0118];

% Aplica o filtro
lpfI = filter(hn,1,upI);
lpfQ = filter(hn,1,upQ);

% figure
% subplot(2,1,1)
% stem(lpfI)
% title('Símbolos I filtrados no modulador')
% xlabel('Amostra')
% ylabel('Amplitude')
% grid on
% subplot(2,1,2)
% stem(lpfQ)
% title('Símbolos Q filtrados no modulador')
% xlabel('Amostra')
% ylabel('Amplitude')
% grid on

%% Heterodinação: banda-base -> banda passante
% Faz a translação da banda-base para banda passante (cuja frequência
% central é a da portadora)
pb = 0:length(lpfI)-1;
XI = cos(2*pi*fc*pb/fs);
XQ = sin(2*pi*fc*pb/fs);
ui = lpfI.*XI;
uq = lpfQ.*XQ;
un = ui - uq;

% figure
% scatter(ui,uq)
% title('Sinal em banda passante')
% grid on

end