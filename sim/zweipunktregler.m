% Zweipunktregler / Q-Mansy / Kuehlwassermanagement
% 08.05.2014
% Version 1
%
% Ein Boiler soll durch Wasserdurchlauf auf Temperatur gebracht
% werden und soll die Temperatur halten. Dazu wird der folgende
% Zweipunktregler benutzt. Die Temperatur wird dadurch erhoeht,
% dass heißes Wasser durch den Boiler flieszt. Der Zulauf wird
% durch eine Pumpe gesteuert.
close all
clear all
clc


% Voreinstellungen
Tset  = 80;                   % Sollwert Boilertemperatur
Tb    = 20;                   % Anfangswert Boilertemperatur
Tu    = 20;                   % Umgebungstemperatur
N     = 4000;                 % Anzahl der Daten (= sek)
t_min = [N/60/N:N/60/N:N/60]; % Zeit in Minuten
state = 0;                    % 0 = Abkuehlen, 1 = Aufheizen
hr    = 0.05;                  % Aufheizrate
%cr    = 0.0005;              % Abkuehlrate (geschaetzt mit Iso)
cr    = 9.2E-4;               % Abkuehlrate: 40 Liter-Boiler
Tbs   = zeros(1,N);           % Speichervektor fuer Boilertemp
stas  = zeros(1,N);           % Speichervektor fuer den Zustand

KH    = 0.1;                 % Kopplungsfaktor der Hysterese

for i = 1:N
  if Tb >= (Tset + Tset*KH)   % Kriterium Kuehlen
    state = 0;
  elseif Tb <= (Tset - Tset*KH) % Kriterium Heizen
    state = 1;
  end
  stats(i) = 10*state;        % Speichern des Zustands

  switch state                % Temperaturreaktion simulieren
  case 0                      % Kuehlen
    Tb = Tb - cr*(Tb - Tu);   % Netonsches Abkuehlungsgesetz
  case 1                      % Heizen
    Tb = Tb + hr;
  end
  Tbs(i) = Tb;                % Speichern der Temperaturwerte
end




% Plotten
figure()
plot(t_min, Tbs,'linewidth', 3, 'Color', [.3 .3 .3], ...
     t_min, stats, 'linewidth', 3, 'Color', [0 0 1])
xlim([0 50])
xlabel('Zeit in Minuten')
ylabel('Temperatur in C')
legend('Boilertemperatur', 'Zustand des Relais', 'location', 'East');
grid on
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4 3])
print('Zweipunktregler','-dtex','-r130');
