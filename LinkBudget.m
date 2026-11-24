%% Constants

gRX = 0; %dBi
freq = [1.17645 1.2276 1.57542]; % L5, L2, L1
c = 3e8;
lambda = c ./ (freq * 1e9);
radEff = 0.65; %Radiation Efficiency for Antenna
pRX = -127; %minimum receive power dBm

orbitAltitude = 100e3; % 100 km
moonRad = 1737.4e3;


%% Calculate the FOV and TX antenna Gain

FOV = 2*asind(moonRad/(moonRad+orbitAltitude));

gTX = radEff*(2/(1-cosd(FOV/2)));
gTXdB = 10*log10(gTX);
gTXdBL = gTXdB - 3; % dBi with a subtraction of 3dB to account for the HPBW 

%% Calculate the Free space loss

d = (moonRad+orbitAltitude)*cosd(FOV/2);
freeSpaceLossdB = 20*log10(4*pi*d ./ lambda);

%% Calculate the Transmit Power

pTXdBm = pRX - gRX - gTXdBL + freeSpaceLossdB;
pTXW = 10.^((pTXdBm - 30) / 10);
