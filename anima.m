function anima(fig, aggiorna, n, passo, etichetta, file_video)
% ANIMA  Riproduce un'animazione con i controlli dentro la finestra:
%        [Pausa/Riprendi]  [Riavvia]  slider del tempo  etichetta
%
% Scorciatoie (con la finestra in primo piano):
%   spazio = pausa/riprendi,  frecce sinistra/destra = un fotogramma indietro/avanti,
%   r = riavvia.
% Trascinando lo slider (o usando le frecce) l'animazione va in pausa.
% A fine corsa resta sull'ultimo fotogramma: "Riprendi" la fa ripartire dall'inizio.
% Chiudere la finestra ferma tutto senza errori.
%
%   fig        : figura dell'animazione
%   aggiorna   : function handle aggiorna(k) che disegna il fotogramma k (1..n)
%   n          : numero di fotogrammi
%   passo      : secondi tra un fotogramma e il successivo
%   etichetta  : function handle etichetta(k) -> testo mostrato accanto allo slider
%   file_video : '' = nessun video; altrimenti nome di un .mp4 (registrato senza controlli,
%                poi si passa alla riproduzione interattiva)

if nargin < 5 || isempty(etichetta),  etichetta  = @(k) sprintf('%d / %d',k,n); end
if nargin < 6 || isempty(file_video), file_video = ''; end
if n < 2
    error('anima:pochiFotogrammi','Servono almeno 2 fotogrammi.');
end

i = 1;                 % fotogramma corrente
in_pausa = false;
sfondo = get(fig,'Color');

%% Controlli nella finestra (striscia in basso)
bp = uicontrol(fig,'Style','pushbutton','String','Pausa','Units','normalized', ...
    'Position',[0.02 0.010 0.09 0.040],'FontSize',10,'Callback',@cb_pausa);
br = uicontrol(fig,'Style','pushbutton','String','Riavvia','Units','normalized', ...
    'Position',[0.12 0.010 0.09 0.040],'FontSize',10,'Callback',@cb_riavvia);
sl = uicontrol(fig,'Style','slider','Min',1,'Max',n,'Value',1, ...
    'SliderStep',[1/(n-1) min(1,10/(n-1))],'Units','normalized', ...
    'Position',[0.23 0.016 0.55 0.028],'Callback',@cb_slider);
et = uicontrol(fig,'Style','text','String','','Units','normalized', ...
    'Position',[0.80 0.010 0.19 0.036],'HorizontalAlignment','left', ...
    'FontSize',10,'BackgroundColor',sfondo);
ctrl = [bp br sl et];
set(fig,'KeyPressFcn',@cb_tasto);
try                    % aggiorna la figura anche mentre si trascina lo slider
    lis = addlistener(sl,'ContinuousValueChange',@(s,~) vai_a(round(get(s,'Value')))); %#ok<NASGU>
catch
end

%% Registrazione video (opzionale, senza controlli)
if ~isempty(file_video)
    set(ctrl,'Visible','off');
    vw = VideoWriter(file_video,'MPEG-4');
    vw.FrameRate = max(1,round(1/passo));
    open(vw);
    for k = 1:n
        aggiorna(k);
        drawnow;
        writeVideo(vw,getframe(fig));
    end
    close(vw);
    fprintf('Video salvato in %s\n',file_video);
    set(ctrl,'Visible','on');
end

%% Riproduzione interattiva
aggiorna(1);
mostra(1);
while ishghandle(fig)
    t0 = tic;
    if ~in_pausa
        if i < n
            i = i + 1;
            aggiorna(i);
            mostra(i);
        else                           % fine corsa: resta sull'ultimo fotogramma
            in_pausa = true;
            set(bp,'String','Riprendi');
        end
    end
    drawnow;                           % qui vengono eseguiti i callback dei controlli
    if ~ishghandle(fig), break; end
    resto = passo - toc(t0);
    if resto > 0, pause(resto); end
end

%% ---------- FUNZIONI ANNIDATE (condividono i, in_pausa, ...) ----------
    function mostra(k)
        % aggiorna slider ed etichetta (lo slider solo se serve, per non "litigare" col mouse)
        if abs(get(sl,'Value') - k) > 0.5, set(sl,'Value',k); end
        set(et,'String',etichetta(k));
    end

    function vai_a(k)
        % salta al fotogramma k e mette in pausa
        i = max(1,min(n,k));
        aggiorna(i);
        mostra(i);
        in_pausa = true;
        set(bp,'String','Riprendi');
    end

    function cb_pausa(src,~)
        if in_pausa && i >= n          % a fine corsa "Riprendi" riparte dall'inizio
            i = 1;
            aggiorna(1);
            mostra(1);
        end
        in_pausa = ~in_pausa;
        if in_pausa
            set(bp,'String','Riprendi');
        else
            set(bp,'String','Pausa');
        end
        if nargin > 0, defocus(src); end
    end

    function cb_riavvia(src,~)
        i = 1;
        aggiorna(1);
        mostra(1);
        in_pausa = false;
        set(bp,'String','Pausa');
        if nargin > 0, defocus(src); end
    end

    function cb_slider(src,~)
        vai_a(round(get(src,'Value')));
        defocus(src);
    end

    function cb_tasto(~,ev)
        switch ev.Key
            case 'space',      cb_pausa();
            case 'rightarrow', vai_a(i+1);
            case 'leftarrow',  vai_a(i-1);
            case 'r',          cb_riavvia();
        end
    end

    function defocus(h)
        % toglie il focus al controllo, cosi' le scorciatoie da tastiera funzionano
        set(h,'Enable','off'); drawnow; set(h,'Enable','on');
    end
end
