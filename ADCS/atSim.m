% GNC test script
clc
clear
close all
consts = load_consts;

% Test Trajectory/Constants
r0 = [0; -1937.3; 0]; % km
v0 = [1.633; 0; .300]; % km/s
t0 = 0;
tf = 86400; % Desired end time, s

% Define Epoch Time
dtime = char(datetime(2026,11,16,12,00,00,0000,"TimeZone","UTCLeapSeconds"));
epochTime = dtime(1:end-2);
et0 = cspice_str2et(epochTime);

% Propagate Orbit
[t,y] = orbprop(r0,v0,t0,tf,consts,et0);

% Antenna boresight in s/c body frame
boresight_B = [0;1;0];  % Example: positive Y

% Controller gains
Kp = diag([20,20,20]);
Kd = diag([40,40,40]);

% GNC update interval
dt = 1.0;  % seconds

% Initial desired attitude
C_IB_des_prev = eye(3);

% GNC Simulation Loop
for k = 1:size(y,1)

    % Current orbit state
    rSC = y(k,1:3)';
    vSC = y(k,4:6)';

    % Current ephemeris time
    et = et0 + t(k);

    % Generate Earth-pointing reference
    C_IB_des = ePoint(rSC,vSC,et,boresight_B);

    % Current estimated spacecraft attitude
    % Replace these with estimator outputs later
    C_IB_est = C_IB_des + randn(3,3)*.01;%C_IB_true;

    % Current estimated angular velocity
    omg_B_est = randn(3,3).*eye(3).*0.01;%omg_B_true;

    % Calculate control torque
    if k == 1
        C_IB_des_prev = C_IB_des;
    end

    [tau_cmd,atError,omg_des_B] = ePController(C_IB_est,omg_B_est, ...
        C_IB_des,C_IB_des_prev,dt,Kp,Kd);

    % Save results
    torqueHist(:,:,k) = tau_cmd';

    atErrHist(:,k) = atError';

    % Update reference
    C_IB_des_prev = C_IB_des;
end


test = 1;