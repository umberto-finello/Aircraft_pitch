%% Definizione del sistema, open loop, closed loop con funzione feedback

clear; close all; clc;

A = [-0.313 56.7 0; -0.0139 -0.426 0; 0 56.7 0];
B = [0.232; 0.0203; 0];
C = [0 0 1];
D = 0;
s = tf('s');
ftca = (1.151*s+0.1774)/(s^3+0.739*s^2+0.921*s);       % funzione di trasferimento circuito aperto (ca)
% ss(A,B,C,D) crea un modello in spazio di stato, nella forma {x'=Ax+Bu ; y=Cx+Du
sistema = ss(A,B,C,D);             % modello

t = (0:0.01:10)';
% step calcola e disegna la risposta del sistema a un ingresso di passo=0.2
step(0.2*ftca,t);
axis([0 10 0 0.8]);
ylabel('angolo di beccheggio (rad)');
title('Risposta al passo a circuito aperto');
pole(ftca)                       % poli della funzione di trasferimento

% Ora aggiungo il controllore C(s):=1 --> circuito chiuso
ftcc = feedback(ftca, 1);        % funzione di trasferimento circuito chiuso (cc)
figure
step(0.2*ftcc);                 % CALCOLO DIRETTO ATTRAVERSO step
ylabel('angolo di beccheggio (rad)'); 
title('Risposta al passo a circuito chiuso');
poli_ftcc = pole(ftcc);
zeri_ftcc = zero(ftcc);
R = 0.2/s; 
Y = zpk(ftcc*R);                  %  zpk fattorizza numeratore e denominatore dell'uscita Y in termini più semplici
[r,p,k] = residue(0.2*[1.151 0.1774],[1 0.739 2.072 0.1774 0]);      % calcolo le costanti

figure
t = (0:0.1:70)'; 
y = 0.2 - 0.0881*exp(-0.08805*t) - exp(-0.3255*t).*(0.1121*cos(1.3816*t)+0.0320*sin(1.3816*t)); 
plot(t,y)                        % SOLUZIONE ANALITICA DA POLI E RESIDUI DELLA ftcc
xlabel( 'tempo (sec)' ); 
ylabel( 'angolo di beccheggio (rad)' ); 
title( 'Risposta al passo a circuito chiuso' );

info = stepinfo(0.2*ftcc);
rise_t = info.RiseTime
sett_time = info.SettlingTime
% close all