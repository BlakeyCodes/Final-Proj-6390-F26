%% ECE 6390
% Orbit Propagator Function
% Blake Berge
% November 2026

%% Inputs
% r0:   [3x1] Inertial position vector in km
% v0:   [3x1] Inertial velocity vector in km/s
% t0:   [scalar] Starting time in s
% tf:   [scalar] End time in s
% m:    [scalar] Mass of satellite, kg
% Cr:   [scalar] Coefficient of reflection for SRP
% epochTime [datetime string]: Epoch Time to evaluate against, format is
% 'YYYY-MM-DDT00:00:00'
%% Outputs
% y: [6xn] Vector of PV states. Length dependent on ode45 options/times

function y = orbprop(r0,v0,t0,tf,m,Cr,area,et0)
consts = load_consts;

% Concatenate pos/vel
pv0 = [r0; v0].*1e3;
tspan = [t0 tf];

%% ode45 call
options = odeset('RelTol',1e-12,'AbsTol',1e-12);
[t,y] = ode45(@(t,y) orb_prop_ode(t,y,consts,m,area,Cr,et0),tspan,pv0,options);

%% Define function w/ odes
    function dydt = orb_prop_ode(tf,pv0,consts,m,area,Cr,et0)
    et = et0 + tf;

    r = pv0(1:3);
    v = pv0(4:6);
    rad = norm(r);

    % Two Body motion
    a2b = (-consts.muM/rad^3)*r;

    % J2 Perturbation
    x = r(1);
    yy = r(2);
    z = r(3);

    factor = 1.5*consts.J2m*consts.muM*consts.Rm^2/rad^5;
    aJ2 = factor * [
        x*(5*z^2/rad^2 - 1);
        yy*(5*z^2/rad^2 - 1);
        z*(5*z^2/rad^2 - 3)];

    % Earth effects
    earthPos = cspice_spkezr('EARTH',et,'J2000','NONE','MOON');
    rEarth = earthPos(1:3).*1e3; %m
    dEarth = rEarth-r;
    aEarth = consts.muE*(dEarth/norm(dEarth)^3 - rEarth/norm(rEarth)^3);

    % SRP
    sunPos = cspice_spkezr('SUN',et,'J2000','NONE','MOON');

    rSun = sunPos(1:3).*1e3; %m
    rSun2Sat = rSun - r;
    sHat = rSun2Sat/norm(rSun2Sat);

    aSRP = (consts.P0*Cr*area/m)*(consts.AU/norm(rSun2Sat))^2*sHat;

    % Sun effects
    aSun = consts.muSun*(rSun2Sat/norm(rSun2Sat)^3 - rSun/norm(rSun)^3);

    % Eclipse Model
    se = rSun/norm(rSun);
    ecl = dot(r,se) < 0;
    perpDist = norm( r - dot(r,se)*se);
    iseclipsed = ecl && perpDist < consts.Rm;

    if iseclipsed
        aSRP = zeros(3,1);
    end

    aTotal = a2b + aJ2 + aEarth + aSun + aSRP;
    dydt = [v; aTotal];
end
end