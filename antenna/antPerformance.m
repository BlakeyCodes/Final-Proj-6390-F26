% antPerformance.m
% Evaluate the dish pattern along the simulated orbit: Earth geometry and
% occultation, ADCS mispointing, thermal surface distortion, and the
% resulting gain / EIRP / C/N0 toward the Earth ground station.
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% ant       [struct] : from antParams
% pat       [struct] : from dishPattern
% consts    [struct] : from load_consts
% t         [nx1]    : sim time from orbprop (s)
% y         [nx6]    : PV states from orbprop (m, m/s), Moon-centred J2000
% et0       [scalar] : epoch, ephemeris seconds past J2000
% atErrHist [3xn]    : (optional) attitude error rot. vectors from atSim (rad). [] = perfect pointing
% Teq       [1xn]    : (optional) s/c temperature from thermSim (K). [] = Tref (no distortion)
%% Outputs
% perf [struct]: time series (all 1xn), see README.md

function perf = antPerformance(ant, pat, consts, t, y, et0, atErrHist, Teq)

    if nargin < 7, atErrHist = []; end
    if nargin < 8, Teq = []; end

    n = numel(t);
    t = t(:).';

    % ---------------- Earth geometry ----------------
    range_m    = zeros(1,n);
    angRad     = zeros(1,n);
    visible    = false(1,n);
    for k = 1:n
        ePV    = cspice_spkezr('EARTH', et0 + t(k), 'J2000', 'NONE', 'MOON');
        rEarth = ePV(1:3)*1e3;                       % km -> m
        rSC    = y(k,1:3).';
        range_m(k) = norm(rEarth - rSC);
        angRad(k)  = asin(consts.Re/range_m(k));     % Earth angular radius seen from s/c
        visible(k) = antEarthVisible(rSC, rEarth, consts.Rm);
    end

    % ---------------- Pointing error (ADCS) ----------------
    if isempty(atErrHist)
        thetaOff = zeros(1,n);
    else
        if size(atErrHist,2) ~= n
            error('antPerformance:size','atErrHist must be 3 x numel(t).');
        end
        thetaOff = antOffBoresight(atErrHist, ant.boresight_B);
    end
    thetaOff_deg = thetaOff*180/pi;

    % ---------------- Thermal distortion (Ruze) ----------------
    if isempty(Teq)
        dT = zeros(1,n);
    else
        if numel(Teq) ~= n
            error('antPerformance:size','Teq must have numel(t) elements.');
        end
        dT = Teq(:).' - ant.Tref_K;
    end
    epsTh   = ant.kappaTh*ant.CTE_perK*abs(dT)*ant.D_m;        % Thermal RMS surface error (m)
    epsTot  = sqrt(ant.surfRMS_m^2 + epsTh.^2);
    etaRuze = exp(-(4*pi*epsTot/ant.lambda).^2);
    dGth_dB = 10*log10(etaRuze/ant.etaRuze);                   % Change vs. nominal pattern

    % ---------------- Gain toward Earth ----------------
    angRad_deg  = angRad*180/pi;
    Gcen_dBi    = pat.gain_dBi(thetaOff_deg) + dGth_dB;               % Earth centre
    Gedge_dBi   = pat.gain_dBi(thetaOff_deg + angRad_deg) + dGth_dB;  % Worst Earth limb
    Gcen_dBi  = reshape(Gcen_dBi,1,[]);
    Gedge_dBi = reshape(Gedge_dBi,1,[]);

    % ---------------- Link ----------------
    EIRP_dBW  = ant.Ptx_dBW - ant.Lline_dB + Gcen_dBi;
    FSPL_dB   = 20*log10(4*pi*range_m/ant.lambda);
    PFD_dBWm2 = EIRP_dBW - 10*log10(4*pi*range_m.^2);
    Prx_dBW   = EIRP_dBW - FSPL_dB + ant.Grx_dBi;
    CN0_dBHz  = Prx_dBW - 10*log10(ant.kB*ant.Tsys_K);

    % Link only exists when the Moon does not block the Earth
    EIRP_dBW(~visible)  = NaN;
    PFD_dBWm2(~visible) = NaN;
    Prx_dBW(~visible)   = NaN;
    CN0_dBHz(~visible)  = NaN;

    % ---------------- Pack ----------------
    perf.t             = t;
    perf.range_m       = range_m;
    perf.earthAngRad_deg = angRad_deg;
    perf.earthVisible  = visible;
    perf.thetaOff_deg  = thetaOff_deg;
    perf.dT_K          = dT;
    perf.epsTot_m      = epsTot;
    perf.dGthermal_dB  = dGth_dB;
    perf.Gcenter_dBi   = Gcen_dBi;
    perf.Gedge_dBi     = Gedge_dBi;
    perf.EIRP_dBW      = EIRP_dBW;
    perf.FSPL_dB       = FSPL_dB;
    perf.PFD_dBWm2     = PFD_dBWm2;
    perf.Prx_dBW       = Prx_dBW;
    perf.CN0_dBHz      = CN0_dBHz;
    perf.visibleFrac   = mean(visible);
end
