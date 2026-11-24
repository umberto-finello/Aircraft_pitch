function muovi_aereo(h, th, de)
% MUOVI_AEREO  Aggiorna la posa di un aereo creato con CREA_AEREO.
%
%   th : angolo di beccheggio [rad]
%   de : deflessione dell'equilibratore [rad]
%        de > 0 = bordo d'uscita verso l'alto (coerente con B(2) > 0 del modello)

if nargin < 3, de = 0; end
g = h.geom;

% l'equilibratore ruota attorno alla sua cerniera di -de
E = ruota(g.elev, -de) + g.cerniera;

posa(h.fin,  g.fin,  th, h);
posa(h.stab, g.stab, th, h);
posa(h.elev, E,      th, h);
posa(h.fus,  g.fus,  th, h);
posa(h.ala,  g.ala,  th, h);
end

%% ---------- FUNZIONI LOCALI ----------
function posa(hp, P, th, h)
% Ruota il poligono P di th attorno al baricentro, lo scala e lo sposta.
Q = h.scala*ruota(P, th) + h.centro;
set(hp, 'XData', Q(1,:), 'YData', Q(2,:));
end

function Q = ruota(P, ang)
% Ruota i punti (colonne di P) di ang radianti in senso antiorario.
Rm = [cos(ang) -sin(ang); sin(ang) cos(ang)];
Q = Rm*P;
end
