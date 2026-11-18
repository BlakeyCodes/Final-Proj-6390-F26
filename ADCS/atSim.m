% GNC test script
% Blake Berge
% ECE 6390
% November 2026
%% Inputs
% t 
% y 
% et0 
% tf
% consts
%% Outputs
% atEstStore
% torqueHist
% atErrHist

function [atEststore, torqueHist, atErrHist] = atSim(t,y,et0,tf,consts)

    % Antenna boresight in s/c body frame
    boresight_B = [0;1;0];  % Example: positive Y

    % GNC update interval
    dt = 1.0;  % seconds
    
    % Initial desired attitude
    at_des_p = eye(3);
    
    % GNC Simulation Loop
    for k = 1:size(y,1)
    
        % Current orbit state
        rSC = y(k,1:3)';
        vSC = y(k,4:6)';
    
        % Current ephemeris time
        et = et0 + t(k);
    
        % Generate Earth-pointing reference
        at_des = ePoint(rSC,vSC,et,boresight_B);
    
        % Current estimated spacecraft attitude
        % Replace these with estimator outputs later
        atEst = at_des + randn(3,3)*.01;%C_IB_true;
        atEststore(:,:,k) = atEst;

        % Current estimated angular velocity
        omg_B_est = randn(3,3).*eye(3).*0.01;%omg_B_true;
    
        % Calculate control torque
        if k == 1
            at_des_p = at_des;
        end
    
        [tau_cmd,atErr,omg_des_B] = ePController(atEst,omg_B_est, ...
            at_des,at_des_p,dt,consts);
    
        % Save results
        torqueHist(:,:,k) = tau_cmd';
    
        atErrHist(:,k) = atErr';
    
        % Update reference
        at_des_p = at_des;
    end
end