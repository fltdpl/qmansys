% Temperaturberechnung / Q-Mansy / Kuehlwassermanagement
% 28.Juni.2014
% Version 1
%
% Berechnung der Abkuehlung.
% Newtonsche Abkuehlungsgesetz:
% T(t) = Tu - c * exp(-kt)
% T(t) -> Temperatur zum Zeitpunkt t
% Tu   -> Umgebungstemperatur
% k    -> Proportionalitaetskoeffizient Bsp. 2.423*10^-4
close all
clear all
clc


% Voreinstellungen
m_W  = 40;         % Masse des Boilerwassers
c_W  = 4180;       % Waermekapazitaet Wasser in kJ*(1/K)*K
T_W  = 70;         % Temperatur des Boilerwassers
T_u  = 20;         % Umgebungstemperatur
k100 = 2.423E-04;  % Proportionalitaetskoeffizient fuer 100 Liter
k40  = 9.2E-4;     % fuer 40 Liter

for t = 1:24*60
  ti(t)   = t/60;
  T100(t) = T_u + (T_W-T_u) * exp(-k100*t);
  T40(t)  = T_u + (T_W-T_u) * exp(-k40*t);
end

figure()
plot(ti,T100,'linewidth', 3, 'Color', [.3 .3 .3], ...
     ti,T40, 'linewidth', 3, 'Color', [0 0 1])
xlim([0 24]);
xlabel('Stunden');
ylabel('Temperatur');
legend('100 Liter', '40 Liter', 'location', 'SouthWest');
grid on
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4 3])
print('Temperaturabkuehlung','-dtex','-r130');
