% antOffBoresight.m
% Angle between the commanded antenna boresight and the actual one, given
% the ADCS attitude-error rotation vector (atErrHist from ADCS/atSim.m).
% A rotation about the boresight itself (roll) gives zero mispointing,
% since the dish pattern is rotationally symmetric.
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% atErr       [3xn] : attitude-error rotation vectors, body frame (rad)
% boresight_B [3x1] : antenna axis in body frame
%% Outputs
% thetaOff [1xn]: off-boresight pointing error (rad)

function thetaOff = antOffBoresight(atErr, boresight_B)

    b = boresight_B(:)/norm(boresight_B);
    n = size(atErr,2);
    thetaOff = zeros(1,n);

    for k = 1:n
        e   = atErr(:,k);
        ang = norm(e);
        if ang < 1e-15
            continue
        end
        u = e/ang;
        % Rodrigues rotation of b about u by ang
        bRot = b*cos(ang) + cross(u,b)*sin(ang) + u*dot(u,b)*(1-cos(ang));
        thetaOff(k) = atan2(norm(cross(b,bRot)), dot(b,bRot));
    end
end
