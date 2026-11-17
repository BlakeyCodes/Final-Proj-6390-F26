% Blake Berge
% Plot Trajectory of satellite/object around the Moon
% November 2026
consts = load_consts;

% Test Trajectory/Constants
r0 = [0; -1937.3; 0]; % km
v0 = [1.533; 0; .300]; % km/s
t0 = 0;
tf = 86400*4; % Desired end time
tspan = [t0 tf]; 
m = 9500; % kg
area = 1; % m^2
Cr = .6;  % Coefficient of reflection

% Define Epoch Time
dtime = char(datetime(2026,11,16,12,00,00,0000,"TimeZone","UTCLeapSeconds"));
epochTime = dtime(1:end-2);
et0 = cspice_str2et(epochTime);

% Propagate Orbit
y = orbprop(r0,v0,t0,tf,m,Cr,area,et0);

figure(1)
img = imread('lroc_color_16bit_srgb_4k.tif');
npanels=75;
view(-43,19);
grid on
hold on
axis vis3d;
[xX, yY, zZ] = ellipsoid(0, 0, 0, consts.Rm, consts.Rm, consts.Rm, npanels);
globe = surf(xX, yY, -zZ, 'FaceColor', 'w', 'EdgeColor',0.5*[1 1 1]);
set(globe, 'FaceColor','texturemap','CData', img, 'EdgeColor','none');
plot3(y(:,1),y(:,2), y(:,3), 'r')
xlabel('X ECI (m)')
ylabel('Y ECI (m)')
zlabel('Z ECI (m)')
title('Orbit');
