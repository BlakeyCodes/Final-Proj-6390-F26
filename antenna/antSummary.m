% antSummary.m
% Print the antenna design, pattern metrics, efficiency budget and
% spacecraft-level checks (and orbit statistics if perf is given).
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% ant    [struct]: from antParams
% pat    [struct]: from dishPattern
% consts [struct]: from load_consts
% perf   [struct]: (optional) from antPerformance
%% Outputs
% Printed to the command window

function antSummary(ant, pat, consts, perf)

    if nargin < 4, perf = []; end
    e = pat.eta;

    fprintf('\n================ HIGH-GAIN ANTENNA SUMMARY ================\n');
    fprintf('Type               : prime-focus parabolic reflector, cos^q feed\n');
    fprintf('Frequency          : %.4f GHz (lambda = %.2f mm)\n', ant.freq_Hz/1e9, ant.lambda*1e3);
    fprintf('Diameter / f/D     : %.3f m / %.2f  (f = %.3f m, depth = %.3f m)\n', ant.D_m, ant.fD, ant.f_m, ant.depth_m);
    fprintf('D/lambda           : %.1f\n', ant.DoverLambda);
    fprintf('Rim half-angle     : %.1f deg\n', ant.psi0*180/pi);
    fprintf('Feed q / gain      : %.3f / %.1f dBi\n', ant.q, ant.feedGain_dBi);
    fprintf('Edge taper         : %.1f dB total (feed %.1f dB + space %.1f dB)\n', ant.edgeTaper_dB, ant.feedTaper_dB, ant.spaceTaper_dB);
    fprintf('Boresight (body)   : [%g %g %g]\n', ant.boresight_B);

    fprintf('\n---- Pattern ----\n');
    fprintf('Peak gain          : %.2f dBi  (ideal %.2f dBi)\n', pat.Gpk_dBi, ant.Gideal_dBi);
    fprintf('HPBW               : %.3f deg   (= %.1f * lambda/D deg)\n', pat.HPBW_deg, pat.HPBW_deg/(ant.lambda/ant.D_m));
    fprintf('First-null BW      : %.3f deg\n', pat.FNBW_deg);
    fprintf('First sidelobe     : %.1f dB at %.2f deg\n', pat.SLL_dB, pat.SLLangle_deg);
    fprintf('Front-to-back      : %.1f dB\n', pat.FB_dB);

    fprintf('\n---- Efficiency budget ----\n');
    fprintf('Taper              : %.3f (%.2f dB)\n', e.taper, 10*log10(e.taper));
    fprintf('Spillover          : %.3f (%.2f dB)\n', e.spill, 10*log10(e.spill));
    fprintf('Blockage           : %.3f (%.2f dB)\n', e.block, 10*log10(e.block));
    fprintf('Ruze (%.2f mm RMS) : %.3f (%.2f dB)\n', ant.surfRMS_m*1e3, e.ruze, 10*log10(e.ruze));
    fprintf('Misc (ohmic etc.)  : %.3f (%.2f dB)\n', e.misc, 10*log10(e.misc));
    fprintf('Aperture total     : %.3f (%.2f dB)\n', e.aperture, 10*log10(e.aperture));

    fprintf('\n---- Spacecraft checks (load_consts) ----\n');
    fprintf('Dish mass          : %.2f kg  (%.2f %% of %g kg s/c)\n', ant.mass_kg, 100*ant.massFrac, consts.m);
    fprintf('Aperture area      : %.3f m^2 (%.2f %% of %g m^2 s/c area)\n', ant.Ageo_m2, 100*ant.areaFrac, consts.area);
    fprintf('Dish SRP force     : %.3g N at 1 AU (Cr = %g)\n', ant.Fsrp_N, consts.Cr);
    fprintf('Earth ang. radius  : %.3f deg at mean Earth-Moon distance\n', asind(consts.Re/384400e3));
    fprintf('HPBW/2 margin      : %.3f deg beyond Earth limb\n', pat.HPBW_deg/2 - asind(consts.Re/384400e3));

    if ~isempty(perf)
        v = perf.earthVisible;
        fprintf('\n---- Along orbit (%d samples, %.1f h) ----\n', numel(perf.t), (perf.t(end)-perf.t(1))/3600);
        fprintf('Earth in view      : %.1f %% of time\n', 100*perf.visibleFrac);
        fprintf('Range              : %.0f - %.0f km\n', min(perf.range_m)/1e3, max(perf.range_m)/1e3);
        sOff = sort(perf.thetaOff_deg);
        p99  = sOff(max(1,ceil(0.99*numel(sOff))));    % 99th percentile (no Stats toolbox needed)
        fprintf('Pointing error     : mean %.3f, 99%% %.3f, max %.3f deg\n', mean(perf.thetaOff_deg), ...
            p99, max(perf.thetaOff_deg));
        fprintf('Thermal gain change: min %.4f dB (dT max %.0f K)\n', min(perf.dGthermal_dB), max(abs(perf.dT_K)));
        if any(v)
            fprintf('Gain to Earth ctr  : min %.2f / mean %.2f dBi (in view)\n', min(perf.Gcenter_dBi(v)), mean(perf.Gcenter_dBi(v)));
            fprintf('Gain to Earth limb : min %.2f dBi (in view)\n', min(perf.Gedge_dBi(v)));
            fprintf('EIRP               : min %.2f dBW (Ptx %.1f W)\n', min(perf.EIRP_dBW(v)), ant.Ptx_W);
            fprintf('FSPL               : %.2f - %.2f dB\n', min(perf.FSPL_dB(v)), max(perf.FSPL_dB(v)));
            fprintf('C/N0 at station    : min %.1f / mean %.1f dB-Hz (G=%.1f dBi, Tsys=%g K)\n', ...
                min(perf.CN0_dBHz(v)), mean(perf.CN0_dBHz(v)), ant.Grx_dBi, ant.Tsys_K);
        end
    end
    fprintf('===========================================================\n\n');
end
