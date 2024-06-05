% FILTRO ADAPATATIVO LMS
function [y, mse] = lms(Iog, Qog, I, Q, step, L, N) %#ok<FNDEF> 
w = zeros(1,L);     % Vetor de coeficientes do filtro
rk = zeros(1,L);    % Vetor regressor
rxIQ = I + 1i*Q;    % Símbolos IQ no receptor
d = Iog + 1i*Qog;   % Símbolos IQ originais

% Implementação do filtro LMS utilizando o vetor regressor rk para fazer
% uma fila FIFO e e percorrer todos vetor aplicando o treinamento
% supervisionado obtendo uma estimativa e um MSE
% Adaptação do passo de aprendizagem
opt = 0.3*N;
for n=1:N
    rk(2:L) = rk(1:L-1);
    rk(1) = rxIQ(n);
    y(n) = rk*w.';
    e(n) = d(n) - y(n);
    w = w + step*e(n)*conj(rk);
    mse(n) = (sum((abs(e)).^2))/n;
    if n == opt
        step = step*0.1;
        opt = opt*2;
    end
end
% Aplicação da estimativa (validação)
for n=(N+1):length(d)
    rk(2:L) = rk(1:L-1);
    rk(1) = rxIQ(n);
    y(n) = rk*w.';
end

% figure
% plot(mse)
% title('Erro médio quadrático')
% xlabel('Iteração')
% ylabel('Erro')
% grid on

end