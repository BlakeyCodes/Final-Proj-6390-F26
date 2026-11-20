% antEarthVisible.m
% Check whether the line of sight from the spacecraft to the Earth's centre
% is blocked by the Moon (sphere of radius Rm centred at the origin).
% Barnabe Marty
% ECE 6390
% November 2026
%% Inputs
% rSC    [3x1]   : s/c position, Moon-centred (m)
% rEarth [3x1]   : Earth position, Moon-centred (m)
% Rm     [scalar]: Moon radius (m)
%% Outputs
% vis [logical]: true if Earth centre is in view

function vis = antEarthVisible(rSC, rEarth, Rm)

    d  = rEarth(:) - rSC(:);
    s  = -dot(rSC(:),d)/dot(d,d);           % Closest approach of segment to Moon centre
    s  = min(max(s,0),1);
    vis = norm(rSC(:) + s*d) > Rm;
end
