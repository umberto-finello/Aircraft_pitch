function a3_saturazione

%% Modello
A = [-0.313 56.7 0; -0.0139 -0.426 0; 0 56.7 0];
B = [0.232; 0.0203; 0];
C = [0 0 1];

%% Opzioni
p_alto     = 50;         % il progetto "aggressivo"
p_basso    = 4;          % il progetto che rispetta il limite (prova anche 4)
R          = 1;
r          = 0.2;        % riferimento [rad]
T          = 6;          % durata (s)
dt         = 0.04;       % passo dei fotogrammi (s)
velocita   = 1;
delta_lim  = 23;         % limite indicativo dell'equilibratore (°)
file_video = '';         % es. 'saturazione.mp4' per registrare un video

lim = deg2rad(delta_lim);

%% Progetto dei due controllori
Ka = lqr(A,B,p_alto*(C'*C),R);   Na = -1/(C*((A-B*Ka)\B));
Kc = lqr(A,B,p_basso*(C'*C),R);  Nc = -1/(C*((A-B*Kc)\B));

%% Simulazione
t = (0:dt:T)';
n = numel(t);
[th_a, de_a] = simula(A,B,C,Ka,Na,r,t,lim,false);   % a) ideale
[th_b, de_b] = simula(A,B,C,Ka,Na,r,t,lim,true);    % b) p alto, saturato
[th_c, de_c] = simula(A,B,C,Kc,Nc,r,t,lim,true);    % c) p basso, saturato

th_all = [th_a th_b th_c];
de_all = [de_a de_b de_c];
th_deg = rad2deg(th_all);
de_deg = rad2deg(de_all);

nomi = {sprintf('p = %g, equilibratore ideale',p_alto), ...
        sprintf('p = %g, equilibratore reale',p_alto), ...
        sprintf('p = %g, equilibratore reale',p_basso)};

fprintf('\nTempo con equilibratore a fondo corsa (+-%g°):\n',delta_lim);
fprintf('  b) p = %g: %.2f s\n', p_alto,  sum(abs(de_b) >= lim-1e-6)*dt);
fprintf('  c) p = %g: %.2f s\n', p_basso, sum(abs(de_c) >= lim-1e-6)*dt);
fprintf('Picco richiesto dal controllore ideale con p = %g: %.1f°\n', p_alto, rad2deg(max(abs(de_a))));
for k = 1:3
    info = stepinfo(th_all(:,k), t, r);
    fprintf('%-38s overshoot %6.2f%%   t salita %.3f s   t assest. %.3f s\n', ...
        nomi{k}, info.Overshoot, info.RiseTime, info.SettlingTime);
end

%% Finestra
colori = [0.85 0.33 0.10; 0.00 0.45 0.74; 0.47 0.67 0.19];
Rr  = [cos(r) -sin(r); sin(r) cos(r)];
rif = Rr*[0 5.5; 0 0];

fig = figure('Color','w','Position',[40 40 1300 720]);

for k = 1:3
    ax(k) = axes('Position',[0.02+0.325*(k-1) 0.52 0.31 0.41]); %#ok<AGROW>
    hold(ax(k),'on');
    xlim(ax(k),[-6 6]); ylim(ax(k),[-6 6]); daspect(ax(k),[1 1 1]); axis(ax(k),'off');
    plot(ax(k),[-6 6],[0 0],':','Color',[0.5 0.5 0.5]);
    plot(ax(k),rif(1,:),rif(2,:),'--','Color',[0.2 0.6 0.2],'LineWidth',1.2);
    aereo(k) = crea_aereo(ax(k),[0 0],1,[0.90 0.92 0.96],1);                      %#ok<AGROW>
    title(ax(k),nomi{k},'FontSize',11);
    txt(k) = text(ax(k),0,-4.8,'','HorizontalAlignment','center','FontSize',10);  %#ok<AGROW>
    avv(k) = text(ax(k),0,5.0,'','HorizontalAlignment','center', 'FontWeight','bold','FontSize',11);                              %#ok<AGROW>
end

axT = axes('Position',[0.06 0.15 0.42 0.29]); hold(axT,'on'); grid(axT,'on');
axD = axes('Position',[0.55 0.15 0.42 0.29]); hold(axD,'on'); grid(axD,'on');
for k = 1:3
    plot(axT,t,th_deg(:,k),'Color',0.5*colori(k,:)+0.5,'LineWidth',1);
    plot(axD,t,de_deg(:,k),'Color',0.5*colori(k,:)+0.5,'LineWidth',1);
end
hR = yline(axT,rad2deg(r),'--k','LineWidth',1);
hL = yline(axD, delta_lim,'--','Color',[0.5 0.5 0.5]);
yline(axD,-delta_lim,'--','Color',[0.5 0.5 0.5]);
for k = 1:3
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
title(axD,sprintf('Deflessione equilibratore'));
%legend(axT,hT,nomi,'Location','southeast','FontSize',8);
legend(axT,[hT hR],[nomi {'Riferimento'}],'Location','southeast','FontSize',9);
legend(axD,[hD hL],[nomi {sprintf('Limiti equilibratore (\\pm%g°)',delta_lim)}], 'Location','northeast','FontSize',9);

%% Animazione con controlli
anima(fig,@aggiorna,n,dt/velocita,@(f) sprintf('t = %.2f s',t(f)),file_video);

%% ---------- FOTOGRAMMA ----------
    function aggiorna(f)
        for j = 1:3
            muovi_aereo(aereo(j), th_all(f,j), de_all(f,j));
            set(txt(j),'String',sprintf('\\theta = %.1f°     \\delta = %.1f°',th_deg(f,j),de_deg(f,j)));
            set(hT(j),'XData',t(1:f),'YData',th_deg(1:f,j));
            set(hD(j),'XData',t(1:f),'YData',de_deg(1:f,j));
        end
        % avvisi sopra ogni aereo
        if abs(de_a(f)) > lim + 1e-9
            set(avv(1),'String','\delta FUORI LIMITE','Color',[0.8 0 0]);
        else
            set(avv(1),'String','');
        end
        if abs(de_b(f)) >= lim - 1e-6
            set(avv(2),'String','SATURAZIONE','Color',[0.9 0.5 0]);
        else
            set(avv(2),'String','');
        end
        if abs(de_c(f)) >= lim - 1e-6
            set(avv(3),'String','SATURAZIONE','Color',[0.9 0.5 0]);
        else
            set(avv(3),'String','');
        end
        set(cT,'Value',t(f));
        set(cD,'Value',t(f));
        title(axT,sprintf('Angolo di beccheggio'));
    end
end

%% ---------- FUNZIONE LOCALE ----------
function [th, de] = simula(A,B,C,K,Nbar,r,t,lim,saturo)
% Risposta al gradino r con la legge delta = Nbar r - K x.
% saturo = false: sistema lineare ideale (delta senza limiti).
% saturo = true : delta = sat(Nbar r - K x), con |delta| <= lim (integrazione con ode45).
if ~saturo
    th = step(r*ss(A-B*K, B*Nbar, C, 0), t);
    de = step(r*ss(A-B*K, B*Nbar, -K, Nbar), t);
else
    f   = @(~,x) A*x + B*max(min(Nbar*r - K*x, lim), -lim);
    opz = odeset('RelTol',1e-8,'AbsTol',1e-10);
    [~,X] = ode45(f, t, zeros(3,1), opz);
    th = X*C';
    de = max(min(Nbar*r - X*K', lim), -lim);
end
end
