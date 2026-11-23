% lla2MCI
% Compute Moon-centered Inertial (i.e. Mean earth, polar axis (MEPA)) from
% latitude, longitude, and altitude (POSITION ONLY)
%% Inputs
% lat [scalar]:  latitude from equator, rads
% lon [scalar]:  longitude from meridian, rads
% h [scalar]:    height above mean elevation, m
% time [scalar]: time since 00:00:00.000 UT
%% Outputs
% PV [3x1]: MEPA or MCI Position coordinates

% Blake Berge
% ECE 6390
% November 2026

function PV = lla2MCI(lat,lon,h,time)
    we = 2.66e-6;% Moon rotation rate (m/s)
    Rm = 1737e3; % Moon Radius (m)
    angle = time*we;
    theta = lon + angle;
    r = (h+Rm)*cos(lat);
    x = r*cos(theta);
    y = r*sin(theta);
    z = (h+Rm)*sin(lat);
    
    PV = [x; y; z;];
end