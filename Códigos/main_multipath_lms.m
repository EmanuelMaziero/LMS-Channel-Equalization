% SISTEMA DE COMUNICAÇÃO COM MODULAÇÃO QPSK PARA ANÁLISE
% DE EQUALIZAÇÃO COM FILTROS ADAPTATIVOS EM UM CANAL COM ECO DEVIDO AO
% CENÁRIO DE MULTIPATH
clear;
close all;
clc;
tic
bs = randi([0 1], 1, 1e5);  % Geração aleatória de bits
sr = 16e6;                  % Taxa de símbolos
fc = 32e6;                  % Frequência da portadora
fs = 256e6;                 % Frequência de amostragem
SNR = -10:1:20;             % Relações sinal-ruído a serem testadas
SNRs = length(SNR);         % Número de SNRs
BER = zeros(1,5);           % Variável da taxa de erro de bit
BERn = zeros(1,5);          % Variável da taxa de erro de bit
EbNo = zeros(1,5);          % Variável da relação EbNo

% Delay profiles do BRAZIL CHANNELS, canais reais com multipath
brA = [1 0 0.2 zeros(1,36-2-1) 0.15 zeros(1,49-36-1) 0.18 zeros(1,94-49-1) 0.21 0.15];
brB = [1 0 0 0 0 0.25 zeros(1,56-5-1) 0.63 zeros(1,70-56-1) 0.45 zeros(1,152-70-1) 0.18 zeros(1,203-152-1) 0.08];
brC = [0.72 1 0 0 0 0 0 0.65 zeros(1,24-7-1) 0.99 zeros(1,37-24-1) 0.75 zeros(1,45-37-1) 0.86];
brD = [0 0 0.99 zeros(1,10-2-1) 0.65 zeros(1,36-10-1) 0.74 zeros(1,49-36-1) 0.86 zeros(1,94-49-1) 1 0.72];
brE = [1 zeros(1,16-1) 1 zeros(1,32-16-1) 1];
dp = cell(5,1);
dp{1,1} = brA;
dp{2,1} = brB;
dp{3,1} = brC;
dp{4,1} = brD;
dp{5,1} = brE;

% Função que faz a modulação e o processo necessário para a transmissão do
% sinal
[Iog, Qog, Mod] = qpsk_mod(bs, sr, fs, fc);

% Variável auxiliar
c = 1;

% Loop que usa cada um dos canais a uma SNR n
for n=1:SNRs
    % Adição de ruído gaussiano branco    
    nMod = awgn(Mod,SNR(n),'measured');

    for dpn=1:size(dp,1)
    % Sinal recebido distorcido pelo canal
    rx = filter(dp{dpn,1},1,nMod);
  
    % Início do processo de demodulação
    [I, Q] = qpsk_demod(sr, fs, fc, rx);
    
    % Equalização do canal com um filtro LMS
    L = 20;         % Ordem do filtro
    N = length(bs)*0.1;       % Número de bits para o treinamento
    step = 0.1;   % Passo de aprendizagem
    [y, mse] = lms_filter(Iog, Qog, I, Q, step, L, N);
    [yn, nmse] = nlms_filter(Iog, Qog, I, Q, step, L, N);
    
    %% Demapp com o sinal filtrado pelo LMS
    % Demapper - pega os símbolos IQ recebidos e divide a constelação em
    % regiões de decisão para tentar recuperar os bits transmitidos
    nn = 1;
    for k=1:length(y)
        if real(y(k)) >= 0 && imag(y(k)) >= 0
            demap(nn:nn+1) = [0 0];
        elseif real(y(k)) < 0 && imag(y(k)) >= 0
            demap(nn:nn+1) = [0 1];
        elseif real(y(k)) < 0 && imag(y(k)) < 0
            demap(nn:nn+1) = [1 1];
        elseif real(y(k)) >= 0 && imag(y(k)) < 0
            demap(nn:nn+1) = [1 0];
        end
        nn = nn + 2;
    end

    % Taxa de Erro de Bit
    BER(c,dpn) = sum(xor(bs(N*2:end), demap(N*2:end)))/length(bs(N*2:end));
 
    %% Demapp com o sinal filtrado pelo NLMS
    % Demapper - pega os símbolos IQ recebidos e divide a constelação em
    % regiões de decisão para tentar recuperar os bits transmitidos
    nn = 1;
    for k=1:length(yn)
        if real(yn(k)) >= 0 && imag(yn(k)) >= 0
            demapn(nn:nn+1) = [0 0];
        elseif real(yn(k)) < 0 && imag(yn(k)) >= 0
            demapn(nn:nn+1) = [0 1];
        elseif real(yn(k)) < 0 && imag(yn(k)) < 0
            demapn(nn:nn+1) = [1 1];
        elseif real(yn(k)) >= 0 && imag(yn(k)) < 0
            demapn(nn:nn+1) = [1 0];
        end
        nn = nn + 2;
    end

    % Taxa de Erro de Bit
    BERn(c,dpn) = sum(xor(bs(N*2:end), demapn(N*2:end)))/length(bs(N*2:end));

    %% Razão energia de símbolo por densidade espectral de potência de ruído e Razão energia de bit por densidade espectral de potência de ruído
    % Ratio of symbol energy to noise power spectral density (EsN0)
    EsNo = 10*log10(0.5*(1/sr)/(1/fs)) + SNR(c);
    % Ratio of bit energy to noise power spectral density (EbN0)
    EbNo(c,dpn) = EsNo - 10*log10(2);  

    if dpn == 1
    if SNR(n) == 20
    scatterplot(y)
    title('Representação do eco na constelação, SNR = 20dB')
    grid on
    end
    end

    end
    % Incremento de variável auxiliar
    c = c + 1;
end

figure
semilogy(EbNo(:,1),BER(:,1),'-*')
hold on
semilogy(EbNo(:,2),BER(:,2),'-x')
semilogy(EbNo(:,3),BER(:,3),'-v')
semilogy(EbNo(:,4),BER(:,4),'-^')
semilogy(EbNo(:,5),BER(:,5),'-o')
xlabel('Eb/No (dB)')
ylabel('BER')
legend('Canal brA','Canal brB','Canal brC','Canal brD','Canal brE','Location','southwest','FontSize',16)
title('BER x Eb/No dos brazil channels equalizados por um LMS')
grid on

figure
semilogy(EbNo(:,1),BERn(:,1),'-*')
hold on
semilogy(EbNo(:,2),BERn(:,2),'-x')
semilogy(EbNo(:,3),BERn(:,3),'-v')
semilogy(EbNo(:,4),BERn(:,4),'-^')
semilogy(EbNo(:,5),BERn(:,5),'-o')
xlabel('Eb/No (dB)')
ylabel('BER')
legend('Canal brA','Canal brB','Canal brC','Canal brD','Canal brE','Location','southwest','FontSize',16)
title('BER x Eb/No dos brazil channels equalizados por um NLMS')
grid on

figure
plot((mse))
hold on
plot((nmse))
hold off
title('Erro médio quadrático')
xlabel('Iteração')
ylabel('Erro')
legend('LMS','NLMS')
grid on
toc