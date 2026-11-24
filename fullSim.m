% fullSim.m
% Simulate all subsystems in one script
% Blake Berge
% ECE 6390
% November 2026

clc
clear
close all

consts = load_consts;

% Test Trajectory/Constants
r0 = [0; -1937.3; 0]; % km
v0 = [1.633; 0; .300]; % km/s
t0 = 0;
tf = 7000; % Desired end time
tspan = [t0 tf]; 
Ti = 273; % Initial s/c temperature (K)

% Define Epoch Time
dtime = char(datetime(2026,11,16,12,00,00,0000,"TimeZone","UTCLeapSeconds"));
epochTime = dtime(1:end-2);
et0 = cspice_str2et(epochTime);

% Propagate Orbit
[t,y] = orbprop(r0,v0,t0,tf,consts,et0);

% Compute ADCS data
[atEststore, torqueHist, atErrHist] = atSim(t,y,et0,tf,consts);

[Teq, Qnet] = thermSim(y(:,1:3),atEststore,et0+t,Ti,consts);

plotAll(t,y,Teq,Qnet,consts)