% Temperaturberechnung / Q-Mansy / Kuehlwassermanagement
% 21.Juni.2014
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
m_M = 100;        % Motormasse in kg
c_M = 0.45;       % Waermekapazitaet Eisen in kJ*(1/K)*K
T_M = 10;         % Temperatur des Motorblocks
m_W = 40;         % Masse des Boilerwassers
c_W = 4.18;       % Waermekapazitaet Wasser in kJ*(1/K)*K
T_W = 70;         % Temperatur des Boilerwassers

% Berechnen der Mischtemperatur
for k = 1:100     % Schleife zum variieren der Motorblocktemperatur 
  T_M(k) = k/2;
  for i = 1:160   % Schleife zum variieren der Boilertemperatur
    T_W(i) = i/2;
    T_X(i,k) = (m_M*c_M*T_M(k) + m_W*c_W*T_W(i))/(m_W*c_W + m_M*c_M);
  end
end

% Plotten
figure()
plot(T_W, T_X(:,10))
xlim([0 80])
xlabel('Temperatur des Boilerwassers in C')
ylabel('Mischtemperatur in C')
grid on

figure()
[x,y] = meshgrid(T_M,T_W);
mesh(x,y,T_X);
xlabel('Motorblocktemperatur in C');
ylabel('Temperatur des Boilerwassers in C');
zlabel('Mischtemperatur');
