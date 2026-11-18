# README for Final Project for ECE 6390 Codebase

This is intended to be a unified location for us to save code, text files, and anything else we want to have under revision control. 


## Getting Started

NASA's spice toolkit, which provides ephemeris data for many celestial bodies, is probably useful, so recommend cloning that repo somewhere easily accessible. It can be found here:
_https://naif.jpl.nasa.gov/naif/toolkit_MATLAB_PC_Windows_VisualC_MATLAB9.x_64bit.html_


Follow the instructions and be sure to run path_init to add the path, changing where needed.
For the earth and moon plotter for the orbit propagator, download the following files from these locations:

**lroc_16bit_srgb_4k.tif**

_https://svs.gsfc.nasa.gov/4720/_'

**earth.png**

_https://www.mathworks.com/matlabcentral/fileexchange/86483-3d-earth-and-celestial-bodies-planet3d/files/planet3D/earth.png_

Finally, leap second and truth ephemeris for celestial bodies for NAIF's SPICE is found at 

_https://naif.jpl.nasa.gov/pub/naif/generic_kernels/fk/_

Download **naif0012.tls** and **de440s.bsp** from the above site. Some navigation is needed to find these text files. They are not downloadable, so copy the text and save it as the required file type.

### File Structure
The repo contains the following folders: 

**ADCS**
This contains the attitude determination and control scripts, including earth-pointing calcs and a simple ADCS controller.

**data**
Leap second and ephemeris info for use in SPICE.

**plot**
Plotting scripts for orbit visualizations, attitude error/vis, and anything else TBD




