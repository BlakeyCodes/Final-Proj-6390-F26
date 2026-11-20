% antParams.m
% Define the spacecraft high-gain antenna (prime-focus parabolic dish) and
% derive every quantity that depends on the spacecraft constants in
% load_consts.m (speed of light, s/c mass, s/c area, SRP constants, ...)
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% consts   [struct]          : output of load_consts
% varargin [name/value pairs]: override any default below, e.g.
%                              antParams(consts,'freq_Hz',26e9,'D_m',0.75)
%% Outputs
% ant [struct]: antenna design + derived parameters (see README.md)

function ant = antParams(consts, varargin)

    p = inputParser;
    p.FunctionName = 'antParams';

    % ---------------- RF / reflector geometry ----------------
    addParameter(p,'freq_Hz',8.475e9);      % X-band downlink, centre of 8450-8500 MHz (Cat. A space research, lunar)
    addParameter(p,'D_m',1.0);              % Reflector diameter (m)
    addParameter(p,'fD',0.40);              % Focal length / diameter
    addParameter(p,'edgeTaper_dB',-11);     % TOTAL rim illumination (feed taper + space attenuation), dB
    addParameter(p,'Dblock_m',0.10);        % Diameter of feed + strut blockage (m)
    addParameter(p,'surfRMS_m',0.25e-3);    % Manufactured RMS surface error (m)
    addParameter(p,'etaMisc',0.95);         % Ohmic * mismatch * polarisation * phase efficiency
    addParameter(p,'backFloor_dBi',-10);    % Gain level assumed behind the aperture plane (dBi)
    addParameter(p,'Nrho',1500);            % Radial samples for the aperture integral

    % ---------------- Mounting / pointing ----------------
    addParameter(p,'boresight_B',[0;1;0]);  % Antenna axis in s/c body frame (matches ADCS/atSim.m)

    % ---------------- Thermal distortion ----------------
    addParameter(p,'CTE_perK',1.0e-6);      % Reflector CTE, quasi-isotropic CFRP (1/K)
    addParameter(p,'kappaTh',0.1);          % Fraction of free expansion that becomes RMS surface error
    addParameter(p,'Tref_K',293);           % Temperature the surface was set at (= T_des in thermSim.m)

    % ---------------- Mass ----------------
    addParameter(p,'arealDensity_kgm2',3.0);% Reflector + backing structure areal density (kg/m^2)
    addParameter(p,'feedMass_kg',1.0);      % Feed + struts (kg)

    % ---------------- Link (for EIRP / C/N0 toward Earth) ----------------
    addParameter(p,'Ptx_W',20);             % RF transmit power at amplifier output (W)
    addParameter(p,'Lline_dB',1.0);         % Amplifier-to-feed line/connector losses (dB)
    addParameter(p,'Grx_dBi',68.2);         % Ground station gain, 34 m class at X-band (dBi)
    addParameter(p,'Tsys_K',30);            % Ground station system noise temperature (K)

    parse(p,varargin{:});
    ant = p.Results;

    % ---------------- Input checks ----------------
    b = ant.boresight_B(:);
    if numel(b) ~= 3 || norm(b) == 0
        error('antParams:boresight','boresight_B must be a non-zero 3x1 vector.');
    end
    ant.boresight_B = b/norm(b);
    if ant.Dblock_m >= ant.D_m
        error('antParams:block','Blockage diameter must be smaller than the dish.');
    end

    % ---------------- Derived RF quantities ----------------
    ant.lambda = consts.c/ant.freq_Hz;               % Wavelength (m)
    ant.k      = 2*pi/ant.lambda;                    % Wavenumber (rad/m)
    ant.f_m    = ant.fD*ant.D_m;                     % Focal length (m)
    ant.depth_m = ant.D_m^2/(16*ant.f_m);            % Dish depth (m)
    ant.psi0   = 2*atan(1/(4*ant.fD));               % Rim half-angle seen from focus (rad)
    ant.DoverLambda = ant.D_m/ant.lambda;
    ant.farField_m  = 2*ant.D_m^2/ant.lambda;        % Fraunhofer distance (m)

    % Feed pattern E_f(psi) = cos(psi)^q. Choose q so the total rim
    % illumination (feed taper * space attenuation (1+cos psi0)/2) equals
    % edgeTaper_dB.
    spaceTaper = (1+cos(ant.psi0))/2;
    ant.spaceTaper_dB = 20*log10(spaceTaper);
    ant.q = (ant.edgeTaper_dB/20 - log10(spaceTaper))/log10(cos(ant.psi0));
    if ant.q <= 0
        error('antParams:taper', ['edgeTaper_dB (%.2f dB) is weaker than the space ' ...
            'attenuation alone (%.2f dB) for f/D = %.2f.'], ant.edgeTaper_dB, ant.spaceTaper_dB, ant.fD);
    end
    ant.feedTaper_dB = 20*ant.q*log10(cos(ant.psi0));
    ant.feedGain_dBi = 10*log10(2*(2*ant.q+1));      % Directivity of a cos^q (field) feed

    ant.Ageo_m2    = pi*ant.D_m^2/4;                 % Aperture area (m^2)
    ant.Gideal_dBi = 10*log10(4*pi*ant.Ageo_m2/ant.lambda^2); % 100 % efficient aperture
    ant.etaRuze    = exp(-(4*pi*ant.surfRMS_m/ant.lambda)^2);

    % ---------------- Spacecraft-level checks (uses load_consts values) ----------------
    a = ant.D_m/2;
    ant.surfArea_m2 = (8*pi*ant.f_m^2/3)*((1 + a^2/(4*ant.f_m^2))^(3/2) - 1); % Paraboloid surface area
    ant.mass_kg     = ant.arealDensity_kgm2*ant.surfArea_m2 + ant.feedMass_kg;
    ant.massFrac    = ant.mass_kg/consts.m;          % Fraction of s/c mass
    ant.areaFrac    = ant.Ageo_m2/consts.area;       % Fraction of s/c SRP area
    % SRP force on the dish aperture at 1 AU, normal incidence, same model as orbprop.m
    ant.Fsrp_N      = consts.P0*consts.Cr*ant.Ageo_m2;

    % ---------------- Link constants ----------------
    ant.kB       = 1.380649e-23;                     % Boltzmann constant (J/K)
    ant.Ptx_dBW  = 10*log10(ant.Ptx_W);
end
