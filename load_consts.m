% Load constants for later use
% Blake Berge
% November 2026
function consts = load_consts
    consts.muM = 4.9028e12;     % Moon SGP (m^3/s^2)
    consts.Rm = 1737400;        % m
    consts.P0 = 4.56e-6;        % N/m^2
    consts.AU = 1.495978707e11; % m
    consts.J2m = 202.7e-6;      % no units
    consts.muE = 3.986e14;      % Earth SGP
    consts.muSun = 1.327e20;    % Sun SGP
end
