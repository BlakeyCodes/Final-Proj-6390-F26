% ePoint.m
% Compute direction from s/c to Earth for a given s/c orbit state and
% boresight
% Also establishes roll reference to angular momentum vector of orbit
%% Inputs
% rSC: [3x1 array]: current s/c position vector
% vSC: [3x1 array]: current s/c velocity vector
% et:  [scalar]   : current  time relative to J2000, seconds
% boresight_B [3x1 array]: Axis on which comms antenna is on the s/c

%% outputs
%C_IB_des [3x3 array]: desired body to inertial attitude that satisfies
%C_IB_des\hat{b}_B = \hat{b}_{Earth}
%
% Blake Berge
% ECE 6390
% November 2026

function C_IB_des = ePoint(rSC,vSC,et,boresight_B)

    % Earth position relative to Moon
    earthPos = cspice_spkezr('EARTH', et, 'J2000', 'NONE', 'MOON');
    rEarth = earthPos(1:3);

    % Earth-pointing direction
    rEarthSC = rEarth - rSC;
    xI = rEarthSC/norm(rEarthSC);

    % Orbital reference direction
    h = cross(rSC, vSC);
    hHat = h/norm(h);

    % Project orbital normal perpendicular to the Earth-pointing direction
    zTemp = hHat - dot(hHat,xI)*xI;

    % Handle near-singular geometry
    if norm(zTemp) < 1e-8
        rHat = rSC/norm(rSC);
        zTemp = rHat - dot(rHat,xI)*xI;
        if norm(zTemp) < 1e-8
            error('Unable to construct attitude reference.');
        end
    end

    zI = zTemp/norm(zTemp);

    yI = cross(zI,xI);
    yI = yI/norm(yI);

    % inertial reference
    C_ref = [xI,yI,zI];

    % s/c body
    bB = boresight_B/norm(boresight_B);

    % body ref direction
    refB = [0;0;1];  
    if abs(dot(refB,bB)) > 0.95
        refB = [0;1;0];
    end

    zB = refB - dot(refB,bB)*bB;
    zB = zB/norm(zB);

    yB = cross(zB,bB);
    yB = yB/norm(yB);

    C_body = [bB,yB,zB];

    % Desired body-to-inertial attitude
    C_IB_des = C_ref*C_body';
end