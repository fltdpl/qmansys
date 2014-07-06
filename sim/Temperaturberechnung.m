% Temperaturberechnung / Q-Mansy / Kuehlwassermanagement
% 21.Juni.2014
% Version 1
%
% Berechnung der Mischtemperatur.
close all
clear all
clc


% Voreinstellungen
m_M  = 100;        % Motormasse in kg
c_M  = 0.45;       % Waermekapazitaet Eisen in kJ*(1/K)*K
T_M  = 10;         % Temperatur des Motorblocks
m_KW = 5;          % Masse Kuehlwasser
m_W  = 40;         % Masse des Boilerwassers
c_W  = 4.18;       % Waermekapazitaet Wasser in kJ*(1/K)*K
T_W  = 70;         % Temperatur des Boilerwassers

% Berechnen der Mischtemperatur
m_F  = m_KW + m_W;
for k = 1:100     % Schleife zum variieren der Motorblocktemperatur 
  T_M(k) = k/2;
  for i = 1:160   % Schleife zum variieren der Boilertemperatur
    if i >= k
      T_W(i)   = i/2;
      % Mischtemperatur: T_KW + T_Boiler
      T_Z(i) = (m_KW*c_W*T_M(k) + m_W*c_W*T_W(i))/(m_W*c_W + m_KW*c_W);
      % Mischtemperatur mit Motorblock
      T_X(i,k) = (m_M*c_M*T_M(k) + m_F*c_W*T_Z(i))/(m_F*c_W + m_M*c_M);
    end
  end
end


%figure()
%[x,y] = meshgrid(T_M,T_W);
%mesh(x,y,T_X);
%xlabel('Motorblocktemperatur in \textdegree C');
%ylabel('Temperatur des Boilerwassers in \textdegree C');
%zlabel('Mischtemperatur');

figure()
hold on
Print1 = plot(T_W, T_X(:,1));
%Print2 = plot(T_W, T_X(:,10));
%Print3 = plot(T_W, T_X(:,20));
%Print4 = plot(T_W, T_X(:,30));
Print5 = plot(T_W(40:1:end), T_X(40:1:end,40));
set(Print1, 'linewidth', 3, 'Color', [.3 .3 .3]);
%set(Print2, 'linewidth', 2, 'Color', [0 1 1]);
%set(Print3, 'linewidth', 2, 'Color', [1 0 0]);
%set(Print4, 'linewidth', 2, 'Color', [0 1 0]);
set(Print5, 'linewidth', 3, 'Color', [0 0 1]);
xlim([0 80]);
xlabel('Temperatur des Boilerwassers in \textdegree C')
hLegend = legend([Print1 Print5], ...
                  'Umgebungstemperatur: 0\ \textdegree C',
                  'Umgebungstemperatur: 20\ \textdegree C',
                  'location', 'SouthEast');
ylabel('Mischtemperatur in \textdegree C')
grid on
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4 3])
print('Tempberechnung','-dtex','-r130');

