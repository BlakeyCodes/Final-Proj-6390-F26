% antPlotPerformance.m
% Plot antenna performance along the orbit (output of antPerformance).
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% ant  [struct]: from antParams
% perf [struct]: from antPerformance
%% Outputs
% fig [figure handle]

function fig = antPlotPerformance(ant, perf)

    th = perf.t/3600;                       % hours
    v  = perf.earthVisible;

    fig = figure('Name','Antenna performance along orbit');
    tl = tiledlayout(5,1,'TileSpacing','compact');
    title(tl, sprintf('HGA performance toward Earth (%.3g GHz, D = %.2f m)', ant.freq_Hz/1e9, ant.D_m));

    nexttile
    yyaxis left;  plot(th, perf.range_m/1e3); ylabel('Range (km)')
    yyaxis right; plot(th, perf.earthAngRad_deg); ylabel('Earth ang. rad. (deg)')
    grid on

    nexttile
    plot(th, perf.thetaOff_deg); grid on
    ylabel('Mispointing (deg)')

    nexttile
    Gc = perf.Gcenter_dBi; Gc(~v) = NaN;
    Ge = perf.Gedge_dBi;   Ge(~v) = NaN;
    plot(th, Gc, th, Ge); grid on
    ylabel('Gain (dBi)')
    legend('to Earth centre','to worst Earth limb','Location','best')

    nexttile
    plot(th, perf.dGthermal_dB); grid on
    ylabel('\DeltaG thermal (dB)')

    nexttile
    yyaxis left;  plot(th, perf.EIRP_dBW); ylabel('EIRP (dBW)')
    yyaxis right; plot(th, perf.CN0_dBHz); ylabel('C/N_0 (dB-Hz)')
    grid on
    xlabel('Sim time (h)  [gaps = Earth occulted by Moon]')

    ax = findobj(tl, 'Type', 'axes');
    linkaxes(ax, 'x');
    xlim(ax(1), [th(1) th(end)]);
end
