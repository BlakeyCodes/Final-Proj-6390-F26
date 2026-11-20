% antRefEnvelope.m
% ITU-R S.672-style reference envelope for a circular-beam satellite
% antenna. Used only as a sanity reference to compare against the
% computed dish pattern (S.672 is written for GSO FSS satellites).
%
%   G = Gm - 3 (psi/psi0)^2                  psi <= a psi0
%   G = Gm + Ls                              a psi0 < psi <= b psi0
%   G = Gm + Ls + 20 - 25 log10(psi/psi0)    b psi0 < psi <= psi1
%   G = 0 dBi                                psi > psi1
%   psi0 = HPBW/2, b = 6.32, a = 2.58/2.88/3.16 for Ls = -20/-25/-30 dB
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% theta_deg [nx1]   : off-boresight angle (deg)
% Gm_dBi   [scalar] : peak gain (dBi)
% HPBW_deg [scalar] : half-power beamwidth (deg)
% Ls_dB    [scalar] : (optional) near-in sidelobe level, -20, -25 or -30 (default -25)
%% Outputs
% Genv_dBi [nx1]: envelope gain (dBi)

function Genv_dBi = antRefEnvelope(theta_deg, Gm_dBi, HPBW_deg, Ls_dB)

    if nargin < 4 || isempty(Ls_dB)
        Ls_dB = -25;
    end
    LsTab = [-20 -25 -30];
    aTab  = [2.58 2.88 3.16];
    a = interp1(LsTab, aTab, Ls_dB, 'linear', 'extrap');
    b = 6.32;

    x = abs(theta_deg(:))/(HPBW_deg/2);
    Genv_dBi = zeros(size(x));

    r1 = x <= a;
    r2 = x > a & x <= b;
    r3 = x > b;

    Genv_dBi(r1) = Gm_dBi - 3*x(r1).^2;
    Genv_dBi(r2) = Gm_dBi + Ls_dB;
    Genv_dBi(r3) = Gm_dBi + Ls_dB + 20 - 25*log10(x(r3));
    Genv_dBi = max(Genv_dBi, 0);           % 0 dBi floor beyond psi1
end
