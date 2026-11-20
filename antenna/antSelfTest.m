% antSelfTest.m
% Verification checks for the antenna code against closed-form results.
% Does not need SPICE. Errors on the first failed check.
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% none
%% Outputs
% Printed PASS lines; throws on failure

function antSelfTest

    antDir   = fileparts(mfilename('fullpath'));
    addpath(fileparts(antDir), antDir);
    consts = load_consts;

    % 1) Near-uniform aperture -> Airy pattern: HPBW = 1.029 lambda/D, SLL = -17.57 dB, eta ~ 1
    ant = antParams(consts,'fD',5,'edgeTaper_dB',-0.05,'Dblock_m',0, ...
        'surfRMS_m',0,'etaMisc',1,'D_m',1);
    pat = dishPattern(ant, (0:0.002:20).');
    hpbwAiry = 1.029*ant.lambda/ant.D_m*180/pi;
    check(abs(pat.HPBW_deg/hpbwAiry - 1) < 0.01, 'Uniform aperture HPBW = 1.029 lambda/D (%.4f vs %.4f deg)', pat.HPBW_deg, hpbwAiry);
    check(abs(pat.SLL_dB + 17.57) < 0.2, 'Uniform aperture first sidelobe = -17.6 dB (%.2f dB)', pat.SLL_dB);
    check(abs(pat.eta.taper - 1) < 0.01, 'Uniform aperture taper efficiency ~ 1 (%.4f)', pat.eta.taper);

    % 2) Default design: classic -11 dB taper numbers
    ant = antParams(consts);
    pat = dishPattern(ant);
    k3 = pat.HPBW_deg/(ant.lambda/ant.D_m);
    check(k3 > 65 && k3 < 75, 'HPBW ~ 70 lambda/D deg for -11 dB taper (%.1f)', k3);
    check(pat.SLL_dB < -22 && pat.SLL_dB > -32, 'First sidelobe in -22..-32 dB (%.1f dB)', pat.SLL_dB);
    check(pat.eta.taper*pat.eta.spill > 0.78 && pat.eta.taper*pat.eta.spill < 0.85, ...
        'Taper*spillover efficiency ~ 0.80-0.83 (%.3f)', pat.eta.taper*pat.eta.spill);

    % 3) Peak gain consistent with the efficiency budget
    Gbud = ant.Gideal_dBi + 10*log10(pat.eta.aperture);
    check(abs(pat.Gpk_dBi - Gbud) < 0.01, 'Peak gain = ideal + efficiency budget (%.3f vs %.3f dBi)', pat.Gpk_dBi, Gbud);

    % 4) Power conservation: lossless, unblocked dish radiates all feed power
    ant = antParams(consts,'Dblock_m',0,'surfRMS_m',0,'etaMisc',1,'backFloor_dBi',-300);
    pat = dishPattern(ant, unique([0:0.002:10, 10:0.01:180]).');
    th  = pat.theta_deg*pi/180;
    Prad = trapz(th, pat.G_lin.*sin(th))/2;      % (1/4pi) * integral G dOmega
    check(abs(Prad - 1) < 0.02, 'Integral of G over sphere = 4 pi (ratio %.4f)', Prad);

    % 5) Pointing geometry
    b = [0;1;0];
    off = antOffBoresight([0.01 0 0; 0 0.3 0; 0 0 0.02].', b);
    check(abs(off(1)-0.01) < 1e-12, 'Tilt about X gives 0.01 rad mispointing');
    check(abs(off(2)) < 1e-12,     'Roll about boresight gives zero mispointing');
    check(abs(off(3)-0.02) < 1e-12, 'Tilt about Z gives 0.02 rad mispointing');

    % 6) Moon occultation
    Rm = consts.Rm; rE = [384400e3;0;0];
    check( antEarthVisible([ 1.9e6;0;0], rE, Rm), 'Earth visible from near side');
    check(~antEarthVisible([-1.9e6;0;0], rE, Rm), 'Earth occulted from far side');
    check( antEarthVisible([0;1.9e6;0], rE, Rm), 'Earth visible from limb (above Moon radius)');

    % 7) Reference envelope continuity
    Gm = 38; hp = 2.5;
    x = [2.88 6.32]*hp/2;
    env = antRefEnvelope([x-1e-9, x+1e-9], Gm, hp, -25);   % [a-, b-, a+, b+]
    % (ITU tabulates a to 2 decimals, so a ~0.1 dB step at a*psi0 is expected)
    check(all(abs(env(1:2)-env(3:4)) < 0.2), 'S.672 envelope continuous at a*psi0 and b*psi0 (max step %.3f dB)', max(abs(env(1:2)-env(3:4))));

    fprintf('\nAll antenna self-tests passed.\n');
end

function check(cond, msg, varargin)
    txt = sprintf(msg, varargin{:});
    if ~cond
        error('antSelfTest:fail','FAIL: %s', txt);
    end
    fprintf('PASS: %s\n', txt);
end
