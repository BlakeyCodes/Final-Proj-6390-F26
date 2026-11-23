% orbitChooser.m
% Determine satellite orbit shells for >=4 sats visible for a given point
% Blake Berge
% ECE 6390
% November 2026

clc; 
clear; 
close all

consts = load_consts;

%% Constellation parameters
numshells = 10;                      % planes (RAAN spacing) per inclination
satshells = 10;                      % sats per plane
a = 1812000;                         % m
e = 0;
incl = deg2rad([27 50 76 86]);       % rad (try one inclination at a time to cut run time)
OMG = (0:numshells-1)*2*pi/numshells;% RAAN, no duplicate at 2*pi
omg = (0:satshells-1)*2*pi/satshells;% in-plane phasing, no duplicate
f = 0;
t0 = 0;  
tf = 7000;
elMask = 5;                          % deg

dtime = char(datetime(2026,11,16,12,00,00,0000,"TimeZone","UTCLeapSeconds"));
epochTime = dtime(1:end-2);
et0 = cspice_str2et(epochTime);

%% Surface sample points (ON the surface)
N = 500;
theta = 2*pi*rand(N,1);
phi = asin(-1 + 2*rand(N,1));
[Xp,Yp,Zp] = sph2cart(theta, phi, consts.Rm);
rsAll = [Xp Yp Zp];
nAll = rsAll./consts.Rm;

%% Propagate every satellite
nSats = numel(incl)*numshells*satshells;
satPos = [];
s = 0;
figure(1); hold on; grid on; axis vis3d; view(-43,19)
img = imread('lroc_color_16bit_srgb_4k.tif');
[xX,yY,zZ] = ellipsoid(0,0,0,consts.Rm,consts.Rm,consts.Rm,75);
globe = surf(xX,yY,-zZ);
set(globe,'FaceColor','texturemap','CData',img,'EdgeColor','none');
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)'); title('Orbit');

for n = 1:numel(incl)
    for m = 1:numshells
        for k = 1:satshells
            [p,v] = eltovec(a,e,incl(n),OMG(m),omg(k),f,consts.muM);
            [t,y] = orbprop(p./1e3, v./1e3, t0, tf, consts, et0);
            pos = y(:,1:3);
            if isempty(satPos)
                satPos = zeros(size(pos,1), 3, nSats);
                tRef = t;
            end
            s = s + 1;
            satPos(:,:,s) = pos;
            plot3(pos(:,1),pos(:,2),pos(:,3),'r')
        end
    end
end
nT = size(satPos,1);

%% Visibility count (vectorized over time and satellites)
timevis = zeros(N,nT);
for j = 1:N
    d = satPos-reshape(rsAll(j,:),1,3);          % nT x 3 x nSats
    rg = sqrt(sum(d.^2,2));
    el = asind(sum(d.*reshape(nAll(j,:),1,3),2)./rg);
    timevis(j,:) = squeeze(sum(el >= elMask,3)).'; % sats visible vs. time
end
scatter3(Xp,Yp,Zp,'bs','filled')
%% Results
minVis = min(timevis, [], 'all');
fracOK = mean(timevis >= 4, 'all');
fprintf('Total satellites: %d\n', nSats);
fprintf('Minimum visible (any point, any time): %d\n', minVis);
fprintf('Fraction of point-time samples with >= 4 sats: %.2f%%\n', 100*fracOK);

figure
plot(tRef(:), min(timevis,[],1), 'r', ...
     tRef(:), median(timevis,1), 'b', ...
     tRef(:), max(timevis,[],1), 'g');
yline(4,'k--');
legend('min over points','median','max over points','4-sat requirement');
xlabel('Time (s)'); ylabel('Satellites visible');