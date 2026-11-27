%% Controllabilità, closed loop, lqr, Nbar, variazioni di p ed R

clear; close all; clc;
A = [-0.313 56.7 0; -0.0139 -0.426 0; 0 56.7 0]; B = [0.232; 0.0203; 0]; C = [0 0 1]; D = 0;
t = 0:0.01:10;
r = rad2deg(0.2);     % riferimento: con questo passiamo da radianti a gradi con il minimo errore

Kal = ctrb(A,B);      % matrice di controllabilità di Kalman, ctrb la crea
rank_Kal = rank(Kal);
if rank_Kal==3
    fprintf('Il sistema è completamente controllabile.\n\n')
else
    fprintf('Il sistema NON è completamente controllabile, male male.\n')
end

% Cerchiamo la matrice K (Kalmann gain) con il metodo lqr
p = 50;
Q = p*(C'*C);
R = 1;
K = lqr(A,B,Q,R);
sist_cc_lqr = ss(A-B*K, B, C, D);            % sistema circuito chiuso con LQR
plot(t, (step(r*sist_cc_lqr,t)), 'r', 'LineWidth', 1.3); grid on; title('Closed loop con LQR (p=50)'); xlabel('Tempo (s)'); ylabel('\theta (°)');

% Questi comandi permettono di ottenere rise time, settling time e overshoot
info = stepinfo(r*sist_cc_lqr);
rise_time = info.RiseTime; settling_time = info.SettlingTime; overshoot = info.Overshoot;

ftcc_lqr = tf(sist_cc_lqr);                 % funzione di trasferimento circuito chiuso con lqr
thetaf_lqr = dcgain(r*ftcc_lqr);              % valore a regime (stady state value)
err_regime_lqr = (r-thetaf_lqr)/r*100;
fprintf('Caso p = %d e R = %d.\nIl theta finale con solo lqr è %.2f°, quindi troppo poco.\nInoltre l''errore a regime è %.2f%%\n', p, R, thetaf_lqr, err_regime_lqr)

% Aggiunta del precompensatore Nbar
Nbar = rscale(A,B,C,D,K);
sist_cc_lqr_Nbar = ss(A-B*K, B*Nbar, C, D);
ftcc_lqr_Nbar = tf(sist_cc_lqr_Nbar);           % ora ho la ft data da lqr dopo aver applicato Nbar
thetaf_Nbar = dcgain(r*ftcc_lqr_Nbar);
err_regime_lqr_Nbar = abs((r-thetaf_Nbar)/r*100);

fprintf('\nRequisiti di progettazione:\n- overshoot < 10%%\n- tempo di salita < 2s\n- tempo di assestamento < 10s\n- errore a regime < 2%%\n\n')
fprintf('Con p = %i e R = %i ho:\n- overshoot = %.2f%%\n- tempo di salita = %.4fs\n- tempo di assestamento = %.4fs\n- errore a regime = %.2d%%\n ', p, R, overshoot, rise_time, settling_time, err_regime_lqr_Nbar)

figure; plot(t, (step(r*sist_cc_lqr,t)), 'r', t, step(r*sist_cc_lqr_Nbar,t), 'b', t, r*ones(size(t)), 'k--', 'LineWidth', 1.3); grid on; title('Closed loop (con LQR) con e senza Nbar (p = 50)'); xlabel('Tempo (s)'); ylabel('\theta (°)'); legend('Closed loop con LQR', 'Closed loop con LQR e Nbar', 'Riferimento');

% figure; step(r*sist_cc_Nbar); grid on; ylabel('angolo di beccheggio (°)'); title('CC con LQR e Nbar (p=50)');

% Sistema con uscita delta (deflessione equilibratore)
theta = step(r*sist_cc_lqr_Nbar, t);
sist_delta = ss(A-B*K, B*Nbar, -K, Nbar);
delta = step(r*sist_delta, t);
% figure; plot(delta, 'LineWidth', 1.5); grid on; xlabel('Tempo (s)'); ylabel('\delta (°)'); title('Deflessione dell''equilibratore (p=50, con Nbar)');

delta_max=max(abs(delta));
fprintf('\nPicco di delta = %.2f°.\n', delta_max);
fprintf('\nIl picco di delta è più di quanto un equilibratore reale possa deflettere.\nIl progetto non è realistico. Mi sembra un problema.\n')

% figure; plot(t, theta, 'r', t, delta, 'b', 'LineWidth', 1.3); grid on; xlabel('Tempo (s)'); ylabel('Angolo (°)'); legend('Angolo di beccheggio (\theta)', 'Deflessione dell''equilibratore (\delta)');
figure;
subplot(2,1,1); plot(t, theta, 'b', t, r*ones(size(t)), 'k--', 'LineWidth', 1.3); grid on; title('Variazione degli angoli di beccheggio e deflessione'); xlabel('Tempo (s)'); ylabel('\theta (°)');
% legend('Angolo di beccheggio', 'Riferimento', 'Location', 'southeast')
legend('','Riferimento', 'Location', 'southeast')

subplot(2,1,2); plot(t, delta, 'r', t, 0*ones(size(t)), 'k--', 'LineWidth', 1.3); grid on; xlabel('Tempo (s)'); ylabel('\delta (°)');
% legend('Angolo di deflessione', 'Riferimento', 'Location', 'northeast')
% legend('', 'Riferimento', 'Location', 'northeast')

S_lqr = valuta(A, B, C, K, Nbar, t);

% Valutazione del costo J
[K,S,P] = lqr(A,B,Q,R);    % dà K, la matrice soluzione dell'equazione di Riccati, i poli a cc (autovalori di A−BK)
x_ss = [0 0 r]'; 
J = x_ss' * S * x_ss;
fprintf('\nIl costo J è %.1f.\n', J)

%% R = 1 fissato, variamo p
t = 0:0.01:3;
pv  = [4 50 200];

figure('Name','Variazione di p');
fprintf('\n------------------ LQR al variare di p (con Nbar e R = 1) ------------------\n');
fprintf('%6s %12s %14s %15s %10s %13s\n', 'p','Overshoot[%]','t salita(s)','t assest.(s)','Errore[%]','max|delta|(°)');

for i = 1:numel(pv)
    K = lqr(A, B, pv(i)*(C'*C), R); Nbar = rscale(A, B, C, D, K);
    S = valuta(A, B, C, K, Nbar, t);       % in S ci sono 3 colonne: theta, delta e stepinfo
    subplot(2,1,1)
    plot(t, S.y, 'LineWidth', 1.3)      % questo restituisce theta
    hold on
    subplot(2,1,2)
    plot(t, S.u, 'LineWidth', 1.3)      % questo restituisce delta
    hold on

    errore = abs(r - S.y(end))/r*100;
    fprintf('%6g %12.2f %14.3f %15.3f %10.3f %13.1f\n', pv(i), S.info.Overshoot, S.info.RiseTime, S.info.SettlingTime, errore, max(abs(S.u)));
end

subplot(2,1,1)
yline(r, 'k--'); grid on; ylabel('\theta (°)')
title('p grande: risposta più veloce...')
legend('p = 4', 'p = 50', 'p = 200', 'Riferimento', 'Location', 'southeast')

subplot(2,1,2)
yline(0, 'k--'); grid on; ylabel('\delta (°)'); xlabel('Tempo (s)')
title('... ma sforzo di controllo più grande (R = 1)')
legend('p = 4', 'p = 50', 'p = 200', 'Riferimento', 'Location', 'northeast')


%% p = 50 fissato, variamo R
t = 0:0.01:3;
p = 50;
Rv  = [0.1 1 10];

figure('Name','Variazione di R');
fprintf('\n------------------ LQR al variare di R (con Nbar e p = 50) ------------------\n');
fprintf('%6s %12s %14s %15s %10s %13s\n', 'R','Overshoot[%]','t salita(s)','t assest.(s)','Errore[%]','max|delta|(°)');

for i = 1:numel(Rv)
    K = lqr(A, B, p*(C'*C), Rv(i)); Nbar = rscale(A, B, C, D, K);
    S = valuta(A, B, C, K, Nbar, t);       % in S ci sono 3 colonne: theta, delta e stepinfo
    subplot(2,1,1)
    plot(t, S.y, 'LineWidth', 1.3)      % questo restituisce theta
    hold on
    subplot(2,1,2)
    plot(t, S.u, 'LineWidth', 1.3)      % questo restituisce delta
    hold on

    errore = abs(r - S.y(end))/r*100;
    fprintf('%6g %12.2f %14.3f %15.3f %10.3f %13.1f\n', Rv(i), S.info.Overshoot, S.info.RiseTime, S.info.SettlingTime, errore, max(abs(S.u)));
end

subplot(2,1,1)
yline(r, 'k--'); grid on; ylabel('\theta (°)')
title('R grande: risposta più lenta...')
legend('R = 0.1', 'R = 1', 'R = 10', 'Riferimento', 'Location', 'southeast')

subplot(2,1,2)
yline(0, 'k--'); grid on; ylabel('\delta (°)'); xlabel('Tempo (s)')
title('... ma sforzo di controllo più piccolo (p = 50)')
legend('R = 0.1', 'R = 1', 'R = 10', 'Riferimento', 'Location', 'northeast')


%% Variazione sia di p che di R
% Questa è l'unica parte finita da Claude perchè da solo non riuscivo a mixare p ed R a livello grafico

t   = 0:0.01:2;
% r   = 0.2;
pv  = [4 50];
Rv  = [0.05 1];

col  = lines(numel(pv));      % un colore per ogni p
stile = {'-', '--'};          % uno stile per ogni R

figure('Name','Variazione di p e R');
fprintf('\n------------------ LQR al variare di p ed R (con Nbar) ------------------\n');
fprintf('%6s %6s %12s %14s %15s %10s %13s\n', 'p','R','Overshoot[%]','t salita(s)','t assest.(s)','Errore[%]','max|delta|(°)');

for i = 1:numel(pv)
    for j = 1:numel(Rv)
        K    = lqr(A, B, pv(i)*(C'*C), Rv(j));
        Nbar = rscale(A, B, C, D, K);
        S    = valuta(A, B, C, K, Nbar, t);

        subplot(2,1,1)
        plot(t, S.y, stile{j}, 'Color', col(i,:), 'LineWidth', 1.3)
        hold on

        subplot(2,1,2)
        plot(t, S.u, stile{j}, 'Color', col(i,:), 'LineWidth', 1.3)
        hold on

        errore = abs(r - S.y(end))/r*100;
        fprintf('%6g %6g %12.2f %14.3f %15.3f %10.3f %13.1f\n', pv(i), Rv(j), S.info.Overshoot, S.info.RiseTime, S.info.SettlingTime, errore, max(abs(S.u)));
    end
end

% Curve per la legenda: colori per p, stili (in nero) per R
subplot(2,1,1)
hp1 = plot(NaN, NaN, '-',  'Color', col(1,:), 'LineWidth', 1.3);
hp2 = plot(NaN, NaN, '-',  'Color', col(2,:), 'LineWidth', 1.3);
hR1 = plot(NaN, NaN, stile{1}, 'Color', 'k', 'LineWidth', 1.3);
hR2 = plot(NaN, NaN, stile{2}, 'Color', 'k', 'LineWidth', 1.3);
hr  = plot([t(1) t(end)], [r r], 'k:', 'LineWidth', 1);             % da togliere per non avere il riferimento
grid on; ylabel('\theta (°)');
title('Variazione simultanea di p e R')
legend([hp1 hp2 hR1 hR2 hr], 'p = 4', 'p = 50', 'R = 0.1', 'R = 1', 'Riferimento', 'Location', 'southeast')   % da togliere per non avere il riferimento
% legend([hp1 hp2 hR1 hR2], 'p = 4', 'p = 50', 'R = 0.1', 'R = 1', 'Location', 'southeast')   % da mettere per non avere il riferimento

subplot(2,1,2)
hp1 = plot(NaN, NaN, '-',  'Color', col(1,:), 'LineWidth', 1.3);
hp2 = plot(NaN, NaN, '-',  'Color', col(2,:), 'LineWidth', 1.3);
hR1 = plot(NaN, NaN, stile{1}, 'Color', 'k', 'LineWidth', 1.3);
hR2 = plot(NaN, NaN, stile{2}, 'Color', 'k', 'LineWidth', 1.3);
hr  = plot([t(1) t(end)], [0 0], 'k:', 'LineWidth', 1);           % da togliere per non avere il riferimento
grid on; ylabel('\delta (°)'); xlabel('Tempo (s)')
legend([hp1 hp2 hR1 hR2 hr], 'p = 4', 'p = 50', 'R = 0.1', 'R = 1', 'Riferimento', 'Location', 'northeast')   % da togliere per non avere il riferimento
% legend([hp1 hp2 hR1 hR2], 'p = 4', 'p = 50', 'R = 0.1', 'R = 1', 'Location', 'northeast')   % da mettere per non avere il riferimento



% close all;



%% ---------- FUNZIONI LOCALI ----------
function S = valuta(A, B, C, K, Nbar, t)
% Simula la risposta al gradino di ampiezza 0.2 rad (in gradi) con la legge delta = Nbar*0.2 - K*x.
r = rad2deg(0.2);
sys_y = ss(A - B*K, B*Nbar, C,  0);          % riferimento: theta
sys_u = ss(A - B*K, B*Nbar, -K, Nbar);       % riferimento: delta
S.y    = step(r*sys_y, t);                 % theta(t)
S.u    = step(r*sys_u, t);                 % delta(t)
S.info = stepinfo(S.y, t(:), r);           % overshoot, tempo di salita, assestamento
end