function [b_abs_proj,b_abs_mag,sigma_bg_real,sigma_bg_imag,sigma_bg_mag,time_out,lasers_wavelength] = ...
    calculate_b_abs_timeav(paas,valve_functionality, time_av)
%calculate_b_abs Calculates absorption coefficients from imported PAAS data
% Background subtraction included
% X, Y and R are converted into m-1 using given f and cell constant
%   -> gain changes are taken into account
%   input                 
%       paas:                   imported paas data
%       valve_functionality:    status of relay 1 and 2 for BG and sample
%       corr_method:            method to calculate b_abs
%       time_av:                averaging time
%
%   For KIT PAAS: valve_functionality = [-1 0; 0 -1];

% ----- Laser information
lasers_wavelength = unique(paas.Laser_WaveLength,'stable');
n_laser = length(lasers_wavelength);
laser_vec = paas.Laser_WaveLength;

% Dataset should start with a background measurement
i = 1;
while (paas.Relay1(i) ~= valve_functionality(1,1))
    paas(i,:) = [];
end

% Dataset should end with a background measurement
i = size(paas,1);
while (paas.Relay1(i) ~= valve_functionality(1,1) && ...
        paas.Relay2(i) ~= valve_functionality(1,2))
    paas(i,:) = [];
    i = i-1;
end

% Calculate f
f = paas.Calibration_Gain ./ paas.Lockin_Gain;

% Cell constant
C_cell = paas.Calbration_CellConstant;

% Correct laser power
paas.X = paas.X ./ paas.Power;
paas.Y = paas.Y ./ paas.Power;
paas.R = paas.R ./ paas.Power;

% Apply cell constant
paas.X = paas.X ./ C_cell .*f;
paas.Y = paas.Y ./ C_cell .*f;
paas.R = paas.R ./ C_cell .*f;

% ----- Detect cycle start (first wavelength)
cycle_start = find(laser_vec == lasers_wavelength(1));

valid_cycles = [];

for k = 1:length(cycle_start)

    idx = cycle_start(k):cycle_start(k)+n_laser-1;

    if idx(end) <= height(paas)

        if all(paas.Laser_WaveLength(idx) == lasers_wavelength)
            valid_cycles = [valid_cycles; idx];
        end

    end
end

n_cycles = size(valid_cycles,1);

% ----- Extract signals
X_cycle = reshape(paas.X(valid_cycles'),n_laser,n_cycles);
Y_cycle = reshape(paas.Y(valid_cycles'),n_laser,n_cycles);

% ----- Cycle time (average of all wavelengths)
time_cycle = mean(paas.TimeStamp(valid_cycles),2);

% ----- Detect BG cycles
is_bg = false(n_cycles,1);

for k = 1:n_cycles

    idx = valid_cycles(k,:);

    if all(paas.Relay1(idx) == valve_functionality(1,1) & ...
           paas.Relay2(idx) == valve_functionality(1,2))

        is_bg(k) = true;
    end

end

% ----- Separate measurement and background
X       = X_cycle(:,~is_bg);
Y       = Y_cycle(:,~is_bg);
time    = time_cycle(~is_bg);

X_bg    = X_cycle(:,is_bg);
Y_bg    = Y_cycle(:,is_bg);
time_bg = time_cycle(is_bg);

% ----- Build complex numbers
S     = X  + 1i*Y;
S_bg  = X_bg + 1i*Y_bg;


%% Time averaging

% Define time bins
dt = hours(time_av);

t0 = dateshift(min(time),'start','hour') + duration(0,30,0);
t1 = dateshift(max(time),'end','hour') - duration(0,30,0);

time_edges = t0:dt:t1;
n_bin = length(time_edges)-1;

% Allocate output
b_abs_proj  = NaN(n_laser,n_bin);
b_abs_mag  = NaN(n_laser,n_bin);
sigma_bg_real = NaN(n_laser,n_bin);
sigma_bg_imag = NaN(n_laser,n_bin);
sigma_bg_mag = NaN(n_laser,n_bin);
time_out = NaT(1,n_bin,'TimeZone',time.TimeZone);
    
% Loop over time bins
for k = 1:n_bin
    
    % bin limits
    t_start = time_edges(k);
    t_end   = time_edges(k+1);
    
    time_out(k) = t_start + (t_end - t_start)/2;
    
    % indices
    ind_sig = time    >= t_start & time    < t_end;
    ind_bg  = time_bg >= t_start & time_bg < t_end;
    
    if sum(ind_bg) < 2
        continue
    end
    
    % mean complex signal
    S_mean = mean(S(:,ind_sig),2,'omitnan');
    
    % mean background
    S_bg_mean = mean(S_bg(:,ind_bg),2,'omitnan');
    
    % background corrected complex signal
    S_corr = S_mean - S_bg_mean;
    
    % ---------------------------------------
    % Method 1: phase-projected absorption (corr_method == 3)
    % ---------------------------------------
    b_abs_proj(:,k) = real(S_corr);
    
    % ---------------------------------------
    % Method 2: magnitude estimator (corr_method == 4)
    % ---------------------------------------
    b_abs_mag(:,k) = abs(S_corr);
    
    % ---------------------------------------
    % background sigma (phase-correct)
    % ---------------------------------------
    N_bg = sum(ind_bg);
    sigma_bg_real(:,k) = std(real(S_bg(:,ind_bg)),0,2,'omitnan') ./ sqrt(N_bg);
    sigma_bg_imag(:,k) = std(imag(S_bg(:,ind_bg)),0,2,'omitnan') ./ sqrt(N_bg);
    sigma_bg_mag(:,k)  = abs(std(S_bg(:,ind_bg),0,2,'omitnan') ./ sqrt(N_bg));

end


end





