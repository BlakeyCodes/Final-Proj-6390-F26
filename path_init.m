% Add absolute paths for mice compatibility
% Blake Berge
% ECE 6390
% November 2026
clc
clear

base_dir = pwd;
addpath('data')
addpath('plot')
addpath('ADCS')
addpath('power')
addpath('radiation')
addpath('thermals')
addpath('antenna')/usage


% Replace with your path to mice here, found here:
% https://naif.jpl.nasa.gov/naif/toolkit_MATLAB_PC_Windows_VisualC_MATLAB9.x_64bit.html
addpath("C:\Users\User\Documents\Job and Personal Stuff\Master's Program\Fall 2026\ECE 6380\Final Project\mice\src\mice")
addpath("C:\Users\User\Documents\Job and Personal Stuff\Master's Program\Fall 2026\ECE 6380\Final Project\mice\lib")

try
    cspice_tkvrsn('toolkit');
    cspice_furnsh(sprintf('%s/data/naif0012.tls',base_dir))
    cspice_furnsh(sprintf('%s/data/de440s.bsp',base_dir))
    fprintf('Successfully Built Mice!')
catch ME
    fprintf('Try again, Mice not initialized')
end