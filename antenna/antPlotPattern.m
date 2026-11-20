% antPlotPattern.m
% Plot the dish radiation pattern: full cut vs. reference envelope, main
% beam with the Earth disk overlaid, polar plot, and 3-D pattern in the
% spacecraft body frame.
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% ant    [struct]: from antParams
% pat    [struct]: from dishPattern
% consts [struct]: from load_consts
% perf   [struct]: (optional) from antPerformance, adds pointing-error band
%% Outputs
% figs [1x4 figure handles]

function figs = antPlotPattern(ant, pat, consts, perf)

    if nargin < 4, perf = []; end

    th  = pat.theta_deg;
    G   = pat.G_dBi;
    Gpk = pat.Gpk_dBi;
    thFull = [-flipud(th(2:end)); th];
    GFull  = [flipud(G(2:end)); G];

    if isempty(perf)
        earthR = asind(consts.Re/384400e3);       % Mean Earth-Moon distance
        offPt  = 0;
    else
        earthR = max(perf.earthAngRad_deg);
        sOff   = sort(perf.thetaOff_deg);
        offPt  = sOff(max(1,ceil(0.99*numel(sOff))));   % 99th percentile mispointing
    end

    ttl = sprintf('%.3g GHz, D = %.2f m, f/D = %.2f, edge taper %.0f dB', ...
        ant.freq_Hz/1e9, ant.D_m, ant.fD, ant.edgeTaper_dB);

    % ---------------- 1) Full cut ----------------
    figs(1) = figure('Name','Antenna gain cut');
    plot(thFull, GFull, 'b', 'LineWidth', 1.2); hold on; grid on
    env = antRefEnvelope(thFull, Gpk, pat.HPBW_deg, -25);
    plot(thFull, env, 'r--', 'LineWidth', 1);
    yline(Gpk-3, 'k:');
    xlim([-180 180]); ylim([Gpk-70, Gpk+5]);
    xlabel('Off-boresight angle \theta (deg)');
    ylabel('Gain (dBi)');
    title({'High-gain antenna radiation pattern', ttl});
    legend('Computed (PO aperture integration)', 'ITU-R S.672-style envelope, L_s = -25 dB', ...
        '-3 dB', 'Location', 'northeast');

    % ---------------- 2) Main beam w/ Earth ----------------
    figs(2) = figure('Name','Antenna main beam');
    lim = max(5, 2*pat.FNBW_deg);
    yl  = [Gpk-40, Gpk+3];
    hE = patch([-earthR earthR earthR -earthR], yl([1 1 2 2]), [0.3 0.6 1], ...
        'FaceAlpha', 0.2, 'EdgeColor', 'none'); hold on
    hP = [];
    if offPt > 0
        hP = patch(offPt + [-earthR earthR earthR -earthR], yl([1 1 2 2]), [1 0.5 0], ...
            'FaceAlpha', 0.15, 'EdgeColor', 'none');
    end
    hG = plot(thFull, GFull, 'b', 'LineWidth', 1.5);
    grid on
    xline([-1 1]*pat.HPBW_deg/2, 'k:');
    yline(Gpk-3, 'k:');
    xlim([-lim lim]); ylim(yl);
    xlabel('Off-boresight angle \theta (deg)');
    ylabel('Gain (dBi)');
    title({'Main beam vs. Earth disk seen from lunar orbit', ...
        sprintf('G_{pk} = %.2f dBi, HPBW = %.2f deg, SLL = %.1f dB', Gpk, pat.HPBW_deg, pat.SLL_dB)});
    if isempty(hP)
        legend([hG hE], 'Gain', sprintf('Earth disk (\\pm%.2f deg)', earthR), 'Location', 'south');
    else
        legend([hG hE hP], 'Gain', sprintf('Earth disk (\\pm%.2f deg)', earthR), ...
            sprintf('Earth disk at 99%% mispointing (%.3f deg)', offPt), 'Location', 'south');
    end

    % ---------------- 3) Polar ----------------
    figs(3) = figure('Name','Antenna polar pattern');
    dyn = 60;
    rr  = max(GFull - Gpk, -dyn);
    polarplot(thFull*pi/180, rr, 'b', 'LineWidth', 1.2);
    pax = gca;
    pax.RLim = [-dyn 0];
    pax.ThetaZeroLocation = 'top';
    pax.ThetaDir = 'clockwise';
    title({'Normalised pattern (dB), boresight up', ttl});

    % ---------------- 4) 3-D pattern in body frame ----------------
    figs(4) = figure('Name','Antenna 3-D pattern (body frame)');
    th3 = unique([0:0.05:5, 5:0.5:30, 30:2:180]) * pi/180;
    ph3 = (0:5:360) * pi/180;
    [TH, PH] = meshgrid(th3, ph3);
    G3  = reshape(pat.gain_dBi(TH(:)*180/pi), size(TH));
    R3  = max(G3 - Gpk + 50, 0);                     % 50 dB dynamic range

    b  = ant.boresight_B;
    e1 = null(b.');                                  % Two unit vectors normal to boresight
    u1 = e1(:,1); u2 = e1(:,2);
    X = R3.*(cos(TH)*b(1) + sin(TH).*(cos(PH)*u1(1) + sin(PH)*u2(1)));
    Y = R3.*(cos(TH)*b(2) + sin(TH).*(cos(PH)*u1(2) + sin(PH)*u2(2)));
    Z = R3.*(cos(TH)*b(3) + sin(TH).*(cos(PH)*u1(3) + sin(PH)*u2(3)));
    surf(X, Y, Z, G3, 'EdgeColor', 'none', 'FaceAlpha', 0.9); hold on
    L = 55;
    quiver3(0,0,0,L,0,0,'k','LineWidth',1.5); text(L,0,0,' X_B');
    quiver3(0,0,0,0,L,0,'k','LineWidth',1.5); text(0,L,0,' Y_B');
    quiver3(0,0,0,0,0,L,'k','LineWidth',1.5); text(0,0,L,' Z_B');
    axis equal; grid on
    cb = colorbar; cb.Label.String = 'Gain (dBi)';
    xlabel('X_B'); ylabel('Y_B'); zlabel('Z_B');
    title({'3-D gain pattern in s/c body frame (radius = dB above peak-50)', ...
        sprintf('Boresight [%g %g %g] points at Earth (ADCS ePoint)', b)});
    view(35, 25);
end
