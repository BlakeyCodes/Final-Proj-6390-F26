% ePController.m
% Given current attitude and angular rate estimates, compute a commanded
% torque to achieve the desired attitude and angular rate
% Blake Berge
% ECE 6390
% November 2026
%% Inputs
% C_IB_est [3x3 array]  : estimated s/c attitude
% omg_B_est [3x3 array] : estimated s/c angular rate
% C_IB_des [3x3 array]  : desired s/c attitude
% C_IB_des_p [3x3 array]: previous " "
% dt [scalar]: timestep length (s)
% consts [struct]: constants

%% Outputs
% tau_cmd [3x3 array]: Commanded output torque
% atErr [3x1 array]: Attitude error from desired
% omg_des_B [3x1 array]: angular rate error from desired

function [tau_cmd, atErr, omg_des_B] = ePController(at_est, omg_B_est, ...
    at_des, at_des_p, dt, consts)

    % Calculate desired angular velocity
    C_delta = at_des*at_des_p';
    omg_des_I = rotvecFromDCM(C_delta)/dt;

    % Express desired angular velocity in the current spacecraft body frame
    omg_des_B = at_est'*omg_des_I;

    % Calculate attitude error
    C_err = at_est'*at_des;
    atErr = rotvecFromDCM(C_err);

    % Angular velocity error
    omg_err = omg_B_est-omg_des_B;

    % PD attitude controller
    tau_cmd = consts.Kp*atErr-consts.Kd*omg_err;

end

% DCM to rotation vector
function e = rotvecFromDCM(C)
    cosTheta = (trace(C)-1)/2;
    cosTheta = max(-1,min(1,cosTheta));
    theta = acos(cosTheta);

    if theta < 1e-8
        e = 0.5*[ ...
            C(3,2)-C(2,3);
            C(1,3)-C(3,1);
            C(2,1)-C(1,2)];

    elseif abs(pi-theta) < 1e-6
        % Near-180-degree rotation: use symmetric part to estimate axis
        [V,D] = eig((C+C')/2);
        [~,idx] = min(abs(diag(D)-1));
        axis = real(V(:,idx));
        axis = axis/norm(axis);

        e = theta*axis;

    else
        axis = (1/(2*sin(theta)))*[ ...
            C(3,2)-C(2,3);
            C(1,3)-C(3,1);
            C(2,1)-C(1,2)];

        e = theta*axis;
    end
end