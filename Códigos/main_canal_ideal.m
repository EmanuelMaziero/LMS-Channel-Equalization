% SISTEMA DE COMUNICAÇÃO COM MODULAÇÃO QPSK PARA ANÁLISE
% DE EQUALIZAÇÃO COM FILTROS ADAPTATIVOS EM UM CANAL COM ECO DEVIDO AO
% CENÁRIO DE MULTIPATH USANDO OS DELAY PROFILES DOS BRAZIL CHANNELS
clear;
close all;
clc;

bs = randi([0 1], 1, 1e5);  % Geração aleatória de bits
sr = 16e6;                  % Taxa de símbolos
fc = 32e6;                  % Frequência da portadora
fs = 256e6;                 % Frequência de amostragem
SNR = -10:1:20;             % Relações sinal-ruído a serem testadas
SNRs = length(SNR);         % Número de SNRs
BER = zeros(1,SNRs);        % Variável da taxa de erro de bit
EbNo = zeros(1,SNRs);       % Variável da relação EbN0

% Função que faz a modulação e o processo necessário para a transmissão do
% sinal
[Iog, Qog, Mod] = qpsk_mod(bs, sr, fs, fc);

% Variável auxiliar
c = 1;

% Loop que varia a SNR de cada transmissão
for n=1:SNRs
    % Adição de ruído gaussiano branco
    nMod = awgn(Mod,SNR(n),'measured');

    % Início do processo de demodulação
    [I, Q] = qpsk_demod(sr, fs, fc, nMod);
    
    % Demodulação QPSK por região de decisão
    nn = 1;
    for k=1:length(I)
        if I(k) >= 0 && Q(k) >= 0
            demap(nn:nn+1) = [0 0];
        elseif I(k) < 0 && Q(k) >= 0
            demap(nn:nn+1) = [0 1];
        elseif I(k) < 0 && Q(k) < 0
            demap(nn:nn+1) = [1 1];
        elseif I(k) >= 0 && Q(k) < 0
            demap(nn:nn+1) = [1 0];
        end
        nn = nn + 2;
    end

    % Taxa de Erro de Bit
    BER(c) = (sum(xor(bs, demap)))/length(bs);

    % Ratio of symbol energy to noise power spectral density (EsN0)
    EsNo = 10*log10(0.5*(1/sr)/(1/fs)) + SNR(c);
    % Ratio of bit energy to noise power spectral density (EbN0)
    EbNo(c) = EsNo - 10*log10(2);

    % Plot de constelação para alguns SNRs
    if rem(c,10) == 0
    scatterplot(I+1i*Q)
    title("Constelação para " + SNR(n+1) + " dB")
    grid on
    end

    % Incremento de variável auxiliar
    c = c + 1;
end

figure
semilogy(EbNo,BER,'-*')
xlabel('Eb/No (dB)')
ylabel('BER')
title('Taxa de Erro de Bits vs Eb/No')
grid on