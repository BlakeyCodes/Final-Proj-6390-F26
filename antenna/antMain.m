% antMain.m
% Driver script: design the spacecraft high-gain dish, compute and plot
% its radiation pattern, and (if SPICE/mice is loaded) evaluate it along
% the orbit using the team's orbprop / atSim / thermSim models.
%
% Run from anywhere after path_init (path_init loads mice + kernels).
% Without mice, only the pattern part runs.
% Barnabe Marty
% ECE 6390
% November 2026

close all

% ---------------- Paths (repo root + sibling folders) ----------------
antDir   = fileparts(mfilename('fullpath'));
repoRoot = fileparts(antDir);
addpath(repoRoot, antDir, fullfile(repoRoot,'ADCS'), fullfile(repoRoot,'thermals'), ...
    fullfile(repoRoot,'plot'), fullfile(repoRoot,'data'));

% ---------------- Antenna design + pattern ----------------
consts = load_consts;
ant    = antParams(consts);     % e.g. antParams(consts,'freq_Hz',26e9,'D_m',0.75) for Ka-band
pat    = dishPattern(ant);

% ---------------- Orbit-coupled performance (needs mice) ----------------
perf = [];
haveSpice = exist('cspice_spkezr','file') > 0;
if haveSpice
    try
        % Same test trajectory / epoch as the team's earlier scripts
        r0 = [0; -1937.3; 0];   % km
        v0 = [1.633; 0; .300];  % km/s
        t0 = 0;
        tf = 86400;             % s
        dtime = char(datetime(2026,11,16,12,00,00,0000,"TimeZone","UTCLeapSeconds"));
        et0 = cspice_str2et(dtime(1:end-2));

        [t,y] = orbprop(r0,v0,t0,tf,consts,et0);                 % y in m, m/s
        [~,~,atErrHist] = atSim(t,y,et0,tf,consts);              % ADCS pointing error
        [Teq,~] = thermSim(y(:,1:3),[],t,ant.Tref_K,consts);     % s/c temperature

        perf = antPerformance(ant,pat,consts,t,y,et0,atErrHist,Teq);
    catch ME
        warning('antMain:orbit','Orbit-coupled analysis skipped: %s', ME.message);
        perf = [];
    end
else
    warning('antMain:noSpice', ['mice (cspice_*) not on path - run path_init first. ' ...
        'Only the stand-alone pattern is computed.']);
end

% ---------------- Report + plots ----------------
antSummary(ant,pat,consts,perf);
antPlotPattern(ant,pat,consts,perf);
if ~isempty(perf)
    antPlotPerformance(ant,perf);
end
