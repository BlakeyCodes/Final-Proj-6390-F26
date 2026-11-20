% dishPattern.m
% Far-field gain pattern of a prime-focus parabolic reflector fed by a
% cos^q feed, computed with the aperture-field (physical optics) method:
%
%   E_a(rho)  = cos(psi)^q * (1+cos(psi))/2,  rho = 2 f tan(psi/2)
%   I(theta)  = 2*pi * Integral_0^a E_a(rho) J0(k rho sin(theta)) rho drho
%   D(theta)  = (4*pi/lambda^2) |I(theta)|^2 / P_ap * ((1+cos(theta))/2)^2
%   G(theta)  = D(theta) * eta_spill * eta_Ruze * eta_misc   (+ spillover lobe)
%
% The field inside the blockage diameter is removed from I(theta) but kept
% in P_ap, so blockage loss and its sidelobe effect are both included.
% The pattern is rotationally symmetric (symmetric feed) and theta is the
% angle off the antenna boresight.
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% ant       [struct]: from antParams
% theta_deg [nx1]   : (optional) off-boresight angles, 0..180 deg
%% Outputs
% pat [struct]:
%   .theta_deg, .G_lin, .G_dBi   pattern (dBi)
%   .Gpk_dBi                     peak gain (dBi)
%   .HPBW_deg, .FNBW_deg         half-power / first-null beamwidth
%   .SLL_dB, .SLLangle_deg       first sidelobe level (rel. to peak) and angle
%   .FB_dB                       front-to-back ratio
%   .eta                         efficiency breakdown
%   .gain_dBi(th)                function handle: gain at any off-axis angle (deg)

function pat = dishPattern(ant, theta_deg)

    if nargin < 2 || isempty(theta_deg)
        theta_deg = unique([0:0.005:10, 10:0.02:30, 30:0.1:180]).';
    end
    theta_deg = theta_deg(:);
    if theta_deg(1) ~= 0
        theta_deg = [0; theta_deg];
    end
    theta = theta_deg*pi/180;

    a   = ant.D_m/2;
    k   = ant.k;
    lam = ant.lambda;

    % ---------------- Aperture field (midpoint rule in rho) ----------------
    Nr   = ant.Nrho;
    drho = a/Nr;
    rho  = ((1:Nr).' - 0.5)*drho;
    psi  = 2*atan(rho/(2*ant.f_m));                    % Feed angle hitting radius rho
    Ea   = cos(psi).^ant.q .* (1+cos(psi))/2;          % Feed pattern * space attenuation
    Eb   = Ea;
    Eb(rho < ant.Dblock_m/2) = 0;                      % Blocked centre

    Pap  = 2*pi*sum(abs(Ea).^2.*rho)*drho;             % Total power in (unblocked) aperture
    I0u  = 2*pi*sum(Ea.*rho)*drho;                     % Boresight integral, no blockage
    I0b  = 2*pi*sum(Eb.*rho)*drho;                     % Boresight integral, with blockage

    % ---------------- Radiation integral (forward hemisphere) ----------------
    fwd  = theta <= pi/2;
    J    = besselj(0, k*sin(theta(fwd))*rho.');        % [Ntheta x Nrho]
    I    = 2*pi*(J*(Eb.*rho))*drho;
    obliq = ((1+cos(theta(fwd)))/2).^2;                % Huygens obliquity factor

    Dap      = zeros(size(theta));
    Dap(fwd) = (4*pi/lam^2)*abs(I).^2/Pap.*obliq;

    % ---------------- Efficiencies ----------------
    eta.taper = abs(I0u)^2/(Pap*ant.Ageo_m2);          % Amplitude taper
    eta.block = abs(I0b)^2/abs(I0u)^2;                 % Central blockage
    eta.spill = 1 - cos(ant.psi0)^(2*ant.q+1);         % Feed power intercepted by dish
    eta.ruze  = ant.etaRuze;                           % Surface error (Ruze)
    eta.misc  = ant.etaMisc;
    eta.aperture = eta.taper*eta.block*eta.spill*eta.ruze*eta.misc;

    % ---------------- Gain ----------------
    Gmain = Dap*eta.spill*eta.ruze*eta.misc;

    % Spillover lobe: feed energy past the rim (psi0 < psi <= 90 deg)
    % radiates directly in direction theta = pi - psi.
    psiS = pi - theta;
    sp   = psiS > ant.psi0 & psiS <= pi/2;
    Gsp  = zeros(size(theta));
    Gsp(sp) = eta.misc*2*(2*ant.q+1)*cos(psiS(sp)).^(2*ant.q);

    G = Gmain + Gsp;

    % Behind the aperture plane the PO aperture model is not valid; use the
    % larger of the spillover lobe and a constant back-radiation level.
    back = theta > pi/2;
    G(back) = max(G(back), 10^(ant.backFloor_dBi/10));

    GdB = 10*log10(max(G, realmin));

    % ---------------- Pattern metrics ----------------
    Gpk = GdB(1);

    i3 = find(GdB <= Gpk-3, 1);
    th3 = interp1(GdB([i3-1 i3]), theta_deg([i3-1 i3]), Gpk-3);

    dG    = diff(GdB);
    iNull = i3 - 1 + find(dG(i3:end) > 0, 1);          % first local minimum
    iSL   = iNull - 1 + find(dG(iNull:end) < 0, 1);    % first local maximum after it

    pat.theta_deg   = theta_deg;
    pat.G_lin       = G;
    pat.G_dBi       = GdB;
    pat.Gpk_dBi     = Gpk;
    pat.HPBW_deg    = 2*th3;
    pat.FNBW_deg    = 2*theta_deg(iNull);
    pat.SLL_dB      = GdB(iSL) - Gpk;
    pat.SLLangle_deg = theta_deg(iSL);
    pat.FB_dB       = Gpk - GdB(end);
    pat.eta         = eta;
    pat.gain_dBi    = @(th) interp1(theta_deg, GdB, min(abs(th),180), 'linear');
end
