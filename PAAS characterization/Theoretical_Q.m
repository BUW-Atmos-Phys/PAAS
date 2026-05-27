%% Theoretical quality factor Q
% Investigation of the effect of temperature, pressure and RH

T = 273.15 + 20; % K
P = 101.325e3;   % Pa
RH = 5;         % in %

% Measured Q
Q_meas = 20;

% Resonator parameters
f0 = 3225;            % Hz 

% Q_transport
Q_trans = Q_transport(f0, T, P, RH, 'moist_air'); % 'moist_air' or 'N2'
fprintf('Q_trans ≈ %.1f\n', Q_trans);

% Q_loss
Q_loss = 1./(1/Q_meas - 1/Q_trans);
fprintf('Q_loss ≈ %.1f\n', Q_loss);


%% Functions
function Q = Q_transport(f0, T, P, RH, gas)
% Q_TRANSPORT
%
% Computes Q_transport using Eq. (7) in Arnott et al., (2006)(boundary layer losses)
%
% INPUTS:
%   f0  - resonance frequency [Hz]
%   T   - temperature [K]
%   P   - pressure [Pa]
%   RH  - relative humidity [%] (only used for 'moist_air')
%   gas - 'moist_air' or 'N2'
%
% OUTPUT:
%   Q_transport

% ---------------------------------------------------------
% Resonator geometry (adjust if needed)
% ---------------------------------------------------------
r = 3.25e-3;   % radius [m] 
L = 49e-3;     % length [m] 


% ---------------------------------------------------------
% Gas properties
% ---------------------------------------------------------
switch gas

    case 'moist_air'
        % --- constants
        Rd = 287.05;
        Rv = 461.5;

        cp_d = 1005;
        cp_v = 1850;

        % --- saturation vapor pressure (Tetens)
        T_C = T - 273.15;
        e_sat = 6.112 .* exp((17.62 .* T_C) ./ (243.12 + T_C)) * 100;

        e = RH/100 .* e_sat;
        p_d = P - e;

        % --- density
        rho = p_d/(Rd*T) + e/(Rv*T);

        % --- specific humidity
        epsilon = Rd/Rv;
        q = epsilon .* e ./ (P - (1 - epsilon).*e);

        % --- heat capacity
        cp = cp_d*(1 - q) + cp_v*q;

        % --- thermal conductivity (approx)
        k = 0.026 + 0.00007*(T - 273.15); % weak T dependence

        % --- dynamic viscosity (Sutherland)
        mu = 1.716e-5 * (T/273.15)^(3/2) * (273.15 + 111)/(T + 111);

        % --- gamma
        R_m = Rd*(1 + 0.61*q);
        cv = cp - R_m;
        gamma = cp / cv;

    case 'N2'
        % --- constants for N2
        R = 296.8;        % J/(kg K)
        cp = 1040;        % J/(kg K)
        cv = cp - R;
        gamma = cp / cv;

        % --- density
        rho = P / (R*T);

        % --- viscosity (Sutherland approx)
        mu = 1.663e-5 * (T/273.15)^(3/2) * (273.15 + 107)/(T + 107);

        % --- thermal conductivity
        k = 0.02583 * (T/300)^0.9;

    otherwise
        error('Unknown gas type')
end

% ---------------------------------------------------------
% Boundary layer thicknesses (Eq. 8)
% ---------------------------------------------------------
d_h = sqrt(mu ./ (rho .* pi .* f0));        % viscous
d_T = sqrt(k ./ (rho .* cp .* pi .* f0));    % thermal

% ---------------------------------------------------------
% Q_transport (Eq. 7)
% ---------------------------------------------------------
inv_Q = d_h/r + (gamma - 1) .* d_T .* (2/L + 1/r); 

Q = 1 ./ inv_Q;

end