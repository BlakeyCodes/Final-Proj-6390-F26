% plotAll.m
% Plot Trajectory of satellite/object around the Moon% Blake Berge
% Blake Berge
% ECE 6390
% November 2026
%% Inputs
% t
% y
% Teq
% Qnet
% consts
%% Outputs
% plots of orbit trajectory, thermal loads, and anything else we want here

function plotAll(t,y,Teq,Qnet,consts)
    close all

    % Plot Lunar Globe + s/c orbits
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


    % Thermal sims
    figure(2)
    plot(t,Teq)
    grid on
    xlabel('Sim Time (s)')
    ylabel('Equilibrium Temperature')

    figure(3)
    plot(t,Qnet)
    grid on
    xlabel('Sim Time (s)')
    ylabel('Net s/c Heat Flux (W)')

end

% Plot Earth (optional)
% earthPos = cspice_spkezr('EARTH',et0 + tf,'J2000','NONE','MOON');
% img2 = imread('earth.png');
% grid on
% hold on
% axis vis3d;
% [xX2, yY2, zZ2] = ellipsoid(earthPos(1)*1e3, earthPos(2)*1e3, earthPos(3)*1e3, consts.Re, consts.Re, consts.Re, npanels);
% globe = surf(xX2, yY2, -zZ2, 'FaceColor', 'w', 'EdgeColor',0.5*[1 1 1]);
% set(globe, 'FaceColor','texturemap','CData', img2, 'EdgeColor','none');