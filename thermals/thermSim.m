% thermSim.m
% Model thermal loads on spacecraft in lunar orbit
% Blake Berge
% ECE 6390
% November 2026
%% Inputs
% rSC [3xn array]  : s/c position vector
% aSc [3x3xn array]: s/c attitude array
% t [nx1]          : Simulation time (s)
% Ti [scalar]      : Starting s/c temperature (K)

%% Outputs
% Estimated heat load on vehicle at a given time
% Teq [1xn array]  : Estimated equilibrium temperature (K)
% Qnet [1xn]       : Estimated net heat load (W)

function [Teq, Qnet] = thermSim(rSC,aSc,t,Ti,consts)

    for n = 1:size(t,1)
        % ePos = cspice_spkezr('EARTH',t,'J2000','NONE','MOON');
        sPos = cspice_spkezr('SUN',t(n),'J2000','NONE','MOON');
    
        T_des = 293; % Desired temperature, K
        
        % Determine if in eclipse
        se = sPos(1:3)/norm(sPos(1:3));
        ecl = dot(rSC(n,:)',se) < 0;
        perpDist = norm(rSC(n,:)' - dot(rSC(n,:)',se)*se);
        iseclipsed = ecl && perpDist < consts.Rm;
    
        % Compute lunar heat flux
        F_alb = consts.Gs/2;
    
        % Heat due to solar radiation
        Q_s = (consts.area/2)*consts.Gs;
    
        % Heat due to albedo effects
        Q_albedo = consts.alpha_m*(consts.area/2)*F_alb*(consts.Rm^2)/(norm(rSC(n,:)) + consts.Rm)^2;
    
        % Generated Heat from s/c equipment
        Q_gen = 1;
        if iseclipsed
            F_mir = 20;
            Q_albedo = 0;
        else
            F_mir = 1023;
        end
    
        % Infrared heat due to lunar surface
        Q_ir = (consts.area/2)*F_mir*(consts.Rm^2)/(norm(rSC(n,:)) + consts.Rm)^2;
    
        % Radiated heat flux
        Q_rad = (consts.area/2)*consts.sigma*T_des^4;
    
        % Net heat load on vehicle
        Qnet(n) = Q_ir + Q_s + Q_albedo + Q_gen + Q_rad;
    
        % Estimated equilibrium temperature
        Teq(n) = (Qnet(n)/((consts.area/2)*consts.sigma))^(1/4);
    end

end