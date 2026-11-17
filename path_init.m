% Add absolute paths for mice compatibility
% Blake Berge
% Nov 16 2026

base_dir = pwd;
% Replace with your path to mice here, found here:
% https://naif.jpl.nasa.gov/naif/toolkit_MATLAB_PC_Windows_VisualC_MATLAB9.x_64bit.html
addpath("C:\Users\User\Documents\Job and Personal Stuff\Master's Program\Fall 2026\ECE 6380\Final Project\mice\src\mice")
addpath("C:\Users\User\Documents\Job and Personal Stuff\Master's Program\Fall 2026\ECE 6380\Final Project\mice\lib")

try
    cspice_tkvrsn('toolkit');
    fprintf('Successfully Built Mice!')
catch ME
    fprintf('Try again, Mice not initialized')
end