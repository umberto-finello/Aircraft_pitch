function a1_storia_progetto
% ANIM_STORIA_PROGETTO  La "storia del progetto" in quattro aerei affiancati,
% tutti con lo stesso riferimento di 0.2 rad:
%   1) circuito aperto: equilibratore fisso a delta = 0.2 rad (come il grafico
%      di modello_e_analisi.m, dove 0.2 e' l'ingresso del gradino)
%   2) circuito chiuso con controllore C(s) = 1       (delta = r - theta)
%   3) LQR senza precompensatore                      (delta = r - K x)
%   4) LQR con precompensatore Nbar                   (delta = Nbar r - K x)
% In basso: theta(t) e delta(t) dei quattro casi.
% Controlli nella finestra: Pausa/Riprendi, Riavvia, slider del tempo.
%
% Richiede anima.m, crea_aereo.m e muovi_aereo.m nella stessa cartella.

%% Modello e controllore LQR
A = [-0.313 56.7 0; -0.0139 -0.426 0; 0 56.7 0];
B = [0.232; 0.0203; 0];
C = [0 0 1];
D = 0;

p = 50;                          % peso LQR
R = 1;
K = lqr(A,B,p*(C'*C),R);
Nbar = -1/(C*((A-B*K)\B));

%% Opzioni
r            = 0.2;              % ampiezza del riferimento [rad]
T            = 15;               % durata (s) (il circuito chiuso con C=1 e' lento)
dt           = 0.05;             % passo dei fotogrammi (s)
velocita     = 1;                % 1 = tempo reale, 2 = doppia velocita', ...
delta_lim    = 23;               % limite indicativo dell'equilibratore [gradi]
clip_disegno = true;             % true: la sagoma disegna delta al massimo a +-delta_lim
                                 %       (i grafici mostrano sempre il valore vero)
file_video   = '';               % es. 'storia_progetto.mp4' per registrare un video

%% Simulazione dei quattro casi
t = (0:dt:T)';
n = numel(t);
th = zeros(n,4);
de = zeros(n,4);

sist = ss(A,B,C,D);

% 1) circuito aperto: ingresso = equilibratore fisso a r
th(:,1) = step(r*sist, t);
de(:,1) = r;

% 2) circuito chiuso con C(s) = 1: delta = r - theta
th(:,2) = step(r*feedback(sist,1), t);
de(:,2) = r - th(:,2);

% 3) LQR senza Nbar: delta = r - K x
th(:,3) = step(r*ss(A-B*K, B, C, D), t);
de(:,3) = step(r*ss(A-B*K, B, -K, 1), t);

% 4) LQR con Nbar: delta = Nbar r - K x
th(:,4) = step(r*ss(A-B*K, B*Nbar, C, D), t);
de(:,4) = step(r*ss(A-B*K, B*Nbar, -K, Nbar), t);

th_deg  = rad2deg(th);
de_deg  = rad2deg(de);
lim_rad = deg2rad(delta_lim);

%% Finestra
nomi   = {'Open loop', 'Closed loop (feedback)', 'LQR senza Nbar', 'LQR con Nbar'};
colori = [0.45 0.45 0.45; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.00 0.45 0.74];
Rr  = [cos(r) -sin(r); sin(r) cos(r)];
rif = Rr*[0 5.5; 0 0];           % direzione di riferimento

fig = figure('Color','w','Position',[40 40 1300 720]);

for k = 1:4
    ax(k) = axes('Position',[0.015+0.248*(k-1) 0.52 0.235 0.41]); %#ok<AGROW>
    hold(ax(k),'on');
    xlim(ax(k),[-6 6]); ylim(ax(k),[-6 6]); daspect(ax(k),[1 1 1]); axis(ax(k),'off');
    plot(ax(k),[-6 6],[0 0],':','Color',[0.5 0.5 0.5]);                         % orizzonte
    plot(ax(k),rif(1,:),rif(2,:),'--','Color',[0.2 0.6 0.2],'LineWidth',1.2);   % riferimento
    aereo(k) = crea_aereo(ax(k),[0 0],1,[0.90 0.92 0.96],1);                    %#ok<AGROW>
    title(ax(k),nomi{k},'FontSize',11);
    txt(k) = text(ax(k),0,-4.8,'','HorizontalAlignment','center','FontSize',10); %#ok<AGROW>
end

axT = axes('Position',[0.06 0.15 0.42 0.29]); hold(axT,'on'); grid(axT,'on');
axD = axes('Position',[0.55 0.15 0.42 0.29]); hold(axD,'on'); grid(axD,'on');

for k = 1:4                                  % curve complete, tenui
    plot(axT,t,th_deg(:,k),'Color',0.5*colori(k,:)+0.5,'LineWidth',1);
    plot(axD,t,de_deg(:,k),'Color',0.5*colori(k,:)+0.5,'LineWidth',1);
end
%yline(axT,rad2deg(r),'--k');
hR = yline(axT, rad2deg(r), '--k', 'LineWidth', 1);
%yline(axD, delta_lim,'--','Color',[0.5 0.5 0.5]);
%yline(axD,-delta_lim,'--','Color',[0.5 0.5 0.5]);
hL = yline(axD,  delta_lim, '--', 'Color',[0.5 0.5 0.5]);
yline(axD, -delta_lim, '--', 'Color',[0.5 0.5 0.5]);

for k = 1:4                                  % curve che si disegnano durante l'animazione
    hT(k) = plot(axT,NaN,NaN,'Color',colori(k,:),'LineWidth',1.8); %#ok<AGROW>
    hD(k) = plot(axD,NaN,NaN,'Color',colori(k,:),'LineWidth',1.8); %#ok<AGROW>
end
cT = xline(axT,0,':k');
cD = xline(axD,0,':k');

xlim(axT,[0 T]); xlim(axD,[0 T]);
ylim(axT,[min(0,min(th_deg(:)))-1, max(th_deg(:))*1.1]);
ylim(axD,[min(-1.2*delta_lim, min(de_deg(:))*1.1), max(de_deg(:))*1.1]);
xlabel(axT,'Tempo (s)'); ylabel(axT,'\theta (°)');
xlabel(axD,'Tempo (s)'); ylabel(axD,'\delta (°)');
legend(axT, [hT hR], [nomi, {sprintf('Riferimento')}], 'Location','northwest','FontSize',9);
legend(axD, [hD hL], [nomi, {sprintf('Limiti elevatore (\\pm%i°)', delta_lim)}], 'Location','northeast','FontSize',9);
if clip_disegno
    title(axD,{sprintf('Deflessione elevatore',delta_lim)});
else
    title(axD,sprintf('Deflessione elevatore (limiti indicativi \\pm%i°)',delta_lim));
end

%% Animazione con controlli
anima(fig,@aggiorna,n,dt/velocita,@(f) sprintf('t = %.2f s',t(f)),file_video);

%% ---------- FOTOGRAMMA ----------
    function aggiorna(f)
        for j = 1:4
            dd = de(f,j);
            if clip_disegno, dd = max(min(dd,lim_rad),-lim_rad); end
            muovi_aereo(aereo(j), th(f,j), dd);
            set(txt(j),'String',sprintf('\\theta = %.1f°     \\delta = %.1f°',th_deg(f,j),de_deg(f,j)));
            set(hT(j),'XData',t(1:f),'YData',th_deg(1:f,j));
            set(hD(j),'XData',t(1:f),'YData',de_deg(1:f,j));
        end
        set(cT,'Value',t(f));
        set(cD,'Value',t(f));
        title(axT,sprintf('Angolo di beccheggio'));
    end
end
