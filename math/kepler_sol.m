% Blake Berge
% September 7 2025
% AE 6353 HW 2 Problem 2

% Kepler's Problem + Newton's method 
function [Eb,f] = kepler_sol(M,e,tol)

% Default values if not given
if isempty(M)
    M = (3*pi)/2; 
end
if isempty(e)
    e = 0.5;
end
if isempty(tol)
    tol = 1e-6;
end

diff = 1;% placeholder
Ea = M;  % Initial Guess for E

while abs(diff) > tol
    Eb = Ea;
    h = Eb - e*sin(Eb) - M;
    h_prime = 1 - e*cos(Eb); % Derivative of h
    Ea = Eb - h/h_prime;

    diff = Ea - Eb;
end

% Use acos function instead of atan to prevent quadrant issues/negative f
% acos function found from wikipedia page on True Anomaly:
% https://en.wikipedia.org/wiki/True_anomaly#From_the_eccentric_anomaly

num = cos(Eb) - e;
dem = 1 - e*cos(Eb);
f = acos(num/dem);

% disp({Eb,f})
end

% Blake Berge
% AE 6353