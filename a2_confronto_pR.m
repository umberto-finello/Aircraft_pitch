function a2_confronto_pR

%% Modello
A = [-0.313 56.7 0; -0.0139 -0.426 0; 0 56.7 0];
B = [0.232; 0.0203; 0];
C = [0 0 1];
D = 0;

%% Opzioni
modo         = 'p';      % 'p' = varia p (R=1) | 'R' = varia R (p=50) | 'pR' = mista
r            = 0.2;      % riferimento [rad]
T            = 3;        % durata (s)
dt           = 0.03;     % passo dei fotogrammi (s)
velocita     = 0.5;      % 0.5 = rallentatore (le risposte durano circa 1 s)
delta_lim    = 23;       % limite indicativo dell'elevatore (°)
clip_disegno = true;     % true: la sagoma disegna delta al massimo a +-delta_lim
file_video   = '';       % es. 'confronto_pR.mp4' per registrare un video

switch modo                      % ogni riga = [p R]
    case 'p',  coppie = [4 1; 50 1];
    % case 'R',  coppie = [50 0.1; 50 1; 50 10; 50 100];
    % case 'pR', coppie = [4 0.1; 4 1; 50 0.1; 50 1];
    otherwise, error('modo deve essere ''p'', ''R'' oppure ''pR''');
end

%% Simulazione
N = size(coppie,1);
t = (0:dt:T)';
n = numel(t);
th = zeros(n,N);
de = zeros(n,N);
nomi = cell(1,N);

fprintf('\n%10s %6s %12s %14s %15s %13s\n','p','R','Overshoot[%]','t salita(s)','t assest.(s)','max|delta|[°]');
for k = 1:N
    K = lqr(A,B,coppie(k,1)*(C'*C),coppie(k,2));
    Nbar = -1/(C*((A-B*K)\B));
    th(:,k) = step(r*ss(A-B*K,B*Nbar,C,D), t);
    de(:,k) = step(r*ss(A-B*K,B*Nbar,-K,Nbar), t);
    nomi{k} = sprintf('p = %g, R = %g',coppie(k,1),coppie(k,2));
    info = stepinfo(th(:,k), t, r);
    fprintf('%10g %6g %12.2f %14.3f %15.3f %13.1f\n',coppie(k,1),coppie(k,2), ...
        info.Overshoot, info.RiseTime, info.SettlingTime, rad2deg(max(abs(de(:,k)))));
end

th_deg  = rad2deg(th);
de_deg  = rad2deg(de);
lim_rad = deg2rad(delta_lim);

%% Finestra
colori = lines(N);
chiari = 0.55*colori + 0.45;
Rr  = [cos(r) -sin(r); sin(r) cos(r)];
rif = Rr*[0 6; 0 0];

fig = figure('Color','w','Position',[50 50 1250 680]);

axA = axes('Position',[0.02 0.12 0.46 0.80]); hold(axA,'on');
xlim(axA,[-6.5 6.5]); ylim(axA,[-6.5 6.5]); daspect(axA,[1 1 1]); axis(axA,'off');
plot(axA,[-6.5 6.5],[0 0],':','Color',[0.5 0.5 0.5]);                       % orizzonte
plot(axA,rif(1,:),rif(2,:),'--','Color',[0.2 0.6 0.2],'LineWidth',1.2);     % riferimento
for k = 1:N
    aereo(k) = crea_aereo(axA,[0 0],1,colori(k,:),0.35,0.6*colori(k,:)); %#ok<AGROW>
    txt(k) = text(axA,-6.2,-3.6-0.75*(k-1),'','Color',0.8*colori(k,:), ...
                  'FontSize',10,'FontWeight','bold'); %#ok<AGROW>
end
hTitA = title(axA,'');

axT = axes('Position',[0.56 0.58 0.41 0.32]); hold(axT,'on'); grid(axT,'on');
axD = axes('Position',[0.56 0.15 0.41 0.30]); hold(axD,'on'); grid(axD,'on');
for k = 1:N
    plot(axT,t,th_deg(:,k),'Color',chiari(k,:),'LineWidth',1);
    plot(axD,t,de_deg(:,k),'Color',chiari(k,:),'LineWidth',1);
end
hR = yline(axT,rad2deg(r),'--k');
hL = yline(axD, delta_lim,'--','Color',[0.5 0.5 0.5]);
yline(axD,-delta_lim,'--','Color',[0.5 0.5 0.5]);
for k = 1:N
    hT(k) = plot(axT,NaN,NaN,'Color',colori(k,:),'LineWidth',1.8); %#ok<AGROW>
    hD(k) = plot(axD,NaN,NaN,'Color',colori(k,:),'LineWidth',1.8); %#ok<AGROW>
end
cT = xline(axT,0,':k');
cD = xline(axD,0,':k');
xlim(axT,[0 T]); xlim(axD,[0 T]);
ylim(axT,[min(0,min(th_deg(:)))-1, max(th_deg(:))*1.1]);
ylim(axD,[min(-1.2*delta_lim, min(de_deg(:))*1.1), max(de_deg(:))*1.1]);
ylabel(axT,'\theta (°)');
xlabel(axD,'Tempo (s)'); ylabel(axD,'\delta (°)');
title(axT,'Angolo di beccheggio');
legend(axT,[hT hR],[nomi {'Riferimento'}],'Location','southeast','FontSize',9);
legend(axD,[hD hL],[nomi {sprintf('Limiti (\\pm%g°)',delta_lim)}], 'Location','northeast','FontSize',9);

if clip_disegno
    title(axD,{sprintf('Deflessione elevatore')});
else
    title(axD,sprintf('Deflessione elevatore'));
end

%% Animazione con controlli
anima(fig,@aggiorna,n,dt/velocita,@(f) sprintf('t = %.2f s',t(f)),file_video);

%% ---------- FOTOGRAMMA ----------
    function aggiorna(f)
        for j = 1:N
            dd = de(f,j);
            if clip_disegno, dd = max(min(dd,lim_rad),-lim_rad); end
            muovi_aereo(aereo(j), th(f,j), dd);
            set(txt(j),'String',sprintf('%s :  \\theta = %5.1f°   \\delta = %6.1f°', ...
                nomi{j},th_deg(f,j),de_deg(f,j)));
            set(hT(j),'XData',t(1:f),'YData',th_deg(1:f,j));
            set(hD(j),'XData',t(1:f),'YData',de_deg(1:f,j));
        end
        set(cT,'Value',t(f));
        set(cD,'Value',t(f));
        set(hTitA,'String',sprintf('t = %.2f s',t(f)));
    end
end
