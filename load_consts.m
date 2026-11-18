% load_consts.m
% Establish physical, controller, and s/c constants in one spot
% Blake Berge
% ECE 6390
% November 2026

function consts = load_consts
    % Physical Constants
    consts.muM = 4.9028e12;     % Moon Standard Gravitational Parameter, SGP (m^3/s^2)
    consts.Rm = 1737400;        % Moon radius (m)
    consts.P0 = 4.56e-6;        % SRP constant at 1 AU (N/m^2)
    consts.AU = 1.495978707e11; % Astronomical Unit (m)
    consts.J2m = 202.7e-6;      % J2 parameter (no units)
    consts.muE = 3.986e14;      % Earth SGP (m^3/s^2)
    consts.muSun = 1.327e20;    % Sun SGP (m^3/s^2)
    consts.Re = 6378130;        % Earth radius (m)
    consts.sigma = 5.67e-8;     % Stefan-Boltzmann constant (W/m^2-K)
    consts.h = 6.6260755e-34;   % Planck Constant (Ws^2)
    consts.c = 299792458;       % c, speed of light (m/s)
    consts.Gs = 1418;           % Solar flux (W/m^2)
    consts.alpha_m = 0.12;      % Lunar albedo (no units)

    % Controller Parameters
    consts.Kp = diag([20,20,20]); % Prop. controller constant
    consts.Kd = diag([40,40,40]); % Deriv. controller constant

    % Spacecraft Parameters
    consts.m = 900;           % Mass
    consts.area = consts.m/5; % Area (m^2) % TODO: Change to dynamic based on s/c attitude
    consts.Cr = 0.5;          % Reflectivity


end
