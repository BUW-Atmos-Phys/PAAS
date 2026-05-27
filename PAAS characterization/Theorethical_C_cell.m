%% THEORETICAL PHOTOACOUSTIC CELL CONSTANT
% Based on Bozóki et al. (2011)
% Investigation of the effect of temperature, pressure and RH

T = 273.15 + 30; % K
P = 101.325e3;   % Pa
RH = 20;         % in %


%% Physical constants
R = 8.314;       % Universal gas constant in J K-1 mol-1

%% Gas properties
addpath('/Users/emma/Documents/m-codes/Termodynamiikkaa')
e = saturation_vapor_pressure_over_water(T);
% fraction of water vapor molecules
h = 0.01 .* RH .* e ./ P;

gamma = 1.4;                % ratio of specific heats (for diatomic gases)
gamma = (7 + h)./(5 + h);   % ratio of specific heats (for air with water vapor)

c   = speed_of_sound_moist_air(T, P, RH); % Speed of sound in moist air
rho = density_moist_air(T, P, RH);        % Density of moist air

%% Resonator parameters
d_res = 6.5e-3;             % resonator diameter [m]
f0    = 3225;               % modulation / resonance frequency [Hz]
Q     = 21;                 % quality factor
G     = 1;                  % geometric overlap factor (~1 for good alignment)

%% Microphone properties
M_mic = 0.032;            % microphone sensitivity [V Pa^-1]

%% Calculate resonator cross-sectional area
A_res = pi*(d_res/2)^2;   % [m^2]

%% Cell constant (pressure response)
% Eq. from Bozóki et al.
C_cell_P = (gamma - 1) * Q * G / (2*pi*f0*A_res);    % [Pa m W^-1]

fprintf('Acoustic cell constant (pressure): %.2f Pa m W^-1\n', C_cell_P)


%% Electronic gains
gain_preamplifier = 580;
gain_lockin       = 300;

gain_total = gain_preamplifier * gain_lockin;

%% Convert to electrical cell constant
C_cell_V = C_cell_P * M_mic * gain_total;   % [V m W^-1]

fprintf('Electrical cell constant: %.0f V m W^-1\n', C_cell_V)







%% Functions
function c = speed_of_sound_moist_air(T, P, RH)
% SPEED_OF_SOUND_MOIST_AIR
%
% Computes speed of sound in moist air
%
% INPUTS:
%   T  - Temperature [K]
%   P  - Pressure [Pa]
%   RH - Relative Humidity [%] (0–100)
%
% OUTPUT:
%   c  - Speed of sound [m/s]

% ---------------------------------------------------------
% Constants
% ---------------------------------------------------------
Rd = 287.05;      % J/(kg·K), dry air
Rv = 461.5;       % J/(kg·K), water vapor

cp_d = 1005;      % J/(kg·K), dry air
cp_v = 1850;      % J/(kg·K), water vapor

% ---------------------------------------------------------
% Saturation vapor pressure (Tetens formula)
% ---------------------------------------------------------
T_C = T - 273.15; % Celsius

e_sat = 6.112 .* exp((17.62 .* T_C) ./ (243.12 + T_C)) * 100; % Pa

% Actual vapor pressure
e = RH / 100 .* e_sat;

% ---------------------------------------------------------
% Mixing ratio
% ---------------------------------------------------------
epsilon = Rd / Rv;
q = epsilon .* e ./ (P - (1 - epsilon) .* e); % specific humidity

% ---------------------------------------------------------
% Moist air properties
% ---------------------------------------------------------
R_m = Rd .* (1 + 0.61 .* q); % approx formulation

cp_m = cp_d .* (1 - q) + cp_v .* q;

cv_m = cp_m - R_m;

gamma = cp_m ./ cv_m;

% ---------------------------------------------------------
% Speed of sound
% ---------------------------------------------------------
c = sqrt(gamma .* R_m .* T);

end

function rho = density_moist_air(T, P, RH)
% DENSITY_MOIST_AIR
%
% Computes density of moist air
%
% INPUTS:
%   T  - Temperature [K]
%   P  - Pressure [Pa]
%   RH - Relative Humidity [%] (0–100)
%
% OUTPUT:
%   rho - Air density [kg/m^3]

% ---------------------------------------------------------
% Constants
% ---------------------------------------------------------
Rd = 287.05;   % J/(kg·K), dry air
Rv = 461.5;    % J/(kg·K), water vapor

% ---------------------------------------------------------
% Saturation vapor pressure (Tetens)
% ---------------------------------------------------------
T_C = T - 273.15;

e_sat = 6.112 .* exp((17.62 .* T_C) ./ (243.12 + T_C)) * 100; % Pa

% Actual vapor pressure
e = RH / 100 .* e_sat;

% ---------------------------------------------------------
% Partial pressures
% ---------------------------------------------------------
p_d = P - e;

% ---------------------------------------------------------
% Density
% ---------------------------------------------------------
rho = p_d ./ (Rd .* T) + e ./ (Rv .* T);

end