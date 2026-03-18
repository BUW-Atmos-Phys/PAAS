%% THEORETICAL PHOTOACOUSTIC CELL CONSTANT
% Based on Bozóki et al. (2011)


%% Physical constants
gamma = 1.4;              % ratio of specific heats (for diatomic gases)

%% Resonator parameters
d_res = 6.5e-3;           % resonator diameter [m]
f_m   = 3275;             % modulation / resonance frequency [Hz]
Q     = 23;               % quality factor
G     = 1;                % geometric overlap factor (~1 for good alignment)

%% Microphone properties
M_mic = 0.032;            % microphone sensitivity [V Pa^-1]

%% Calculate resonator cross-sectional area
A_res = pi*(d_res/2)^2;   % [m^2]

%% Cell constant (pressure response)
% Eq. from Bozóki et al.
C_cell_P = (gamma - 1) * Q * G / (2*pi*f_m*A_res);    % [Pa m W^-1]

fprintf('Acoustic cell constant (pressure): %.2f Pa m W^-1\n', C_cell_P)


%% Electronic gains
gain_preamplifier = 580;
gain_lockin       = 300;

gain_total = gain_preamplifier * gain_lockin;

%% Convert to electrical cell constant
C_cell_V = C_cell_P * M_mic * gain_total;   % [V m W^-1]

fprintf('Electrical cell constant: %.0f V m W^-1\n', C_cell_V)
