% eltovec.m
% Derived from work done in AE 6353
% Convert orbit elements to ECEF
%% Inputs
% Keplerian orbital elements
%% Outputs
% Inertial state vector
% Blake Berge
% ECE 6390
% November 2026
function [ECIpos,ECIvel] = eltovec(a,e,i,OMG,omg,f,mu)

p = a*(1-e^2);
rmag = p/(1+e*cos(f)); % BMW 1.5-4

% Perifocal Position
Pr = rmag*cos(f); 
Qr = rmag*sin(f);
perifocalr = [Pr, Qr, 0]'; 

% Perifocal Velocity
Pv = sqrt(mu/p)*-sin(f);
Qv = sqrt(mu/p)*(e + cos(f));
perifocalv = [Pv, Qv, 0]';

% From class notes:
R1 = [cos(OMG) -sin(OMG) 0;
    sin(OMG) cos(OMG) 0;
    0 0 1];
R2 = [1 0 0;
    0 cos(i) -sin(i);
    0 sin(i) cos(i)];
R3 = [cos(omg) -sin(omg) 0;
    sin(omg) cos(omg) 0;
    0 0 1];

% Rotate to ECI:
ECIpos = R1*R2*R3*perifocalr;  % m
ECIvel = R1*R2*R3*perifocalv;  % m/s

end