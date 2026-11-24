function h = crea_aereo(ax, centro, scala, colore, alfa, colElev)
% CREA_AEREO  Disegna la sagoma di un aereo (vista laterale, muso a destra)
% nell'asse ax e restituisce una struttura h da passare a MUOVI_AEREO.
%
%   centro  : [x y] del baricentro nell'asse          (default [0 0])
%   scala   : fattore di scala della sagoma            (default 1)
%   colore  : colore di fusoliera e ali [r g b]        (default grigio-azzurro)
%   alfa    : trasparenza, 1 = opaco (< 1 per i "fantasmi")
%   colElev : colore dell'equilibratore                (default rosso)
%
% La geometria e' la stessa di animazione1.m.

if nargin < 2 || isempty(centro),  centro  = [0 0]; end
if nargin < 3 || isempty(scala),   scala   = 1; end
if nargin < 4 || isempty(colore),  colore  = [0.90 0.92 0.96]; end
if nargin < 5 || isempty(alfa),    alfa    = 1; end
if nargin < 6 || isempty(colElev), colElev = [0.85 0.30 0.30]; end

a = linspace(0, 2*pi, 60);
g.fus      = [4*cos(a); 0.5*sin(a)];                         % fusoliera
g.ala      = [0.8 0 -1.8 -1.2; -0.3 -0.3 -0.9 -0.9];         % ala
g.fin      = [-2.8 -3.9 -4.1 -3.6; 0.3 0.3 1.9 1.9];         % deriva verticale
g.stab     = [-2.7 -3.8 -3.8 -2.7; 0.07 0.07 -0.07 -0.07];   % stabilizzatore (fisso)
L          = 1.2;                                            % lunghezza equilibratore
g.elev     = [0 -L -L 0; 0.07 0.07 -0.07 -0.07];             % equilibratore (coordinate locali)
g.cerniera = [-3.8; 0];                                      % cerniera dell'equilibratore

h.geom   = g;
h.centro = centro(:);
h.scala  = scala;

op = {'EdgeColor','k','FaceAlpha',alfa,'EdgeAlpha',max(alfa,0.4)};
h.fin  = patch(ax, NaN, NaN, 0.85*colore, op{:});
h.stab = patch(ax, NaN, NaN, 0.65*colore, op{:});
h.elev = patch(ax, NaN, NaN, colElev,     op{:});
h.fus  = patch(ax, NaN, NaN, colore,      op{:});
h.ala  = patch(ax, NaN, NaN, 0.65*colore, op{:});

muovi_aereo(h, 0, 0);
end
