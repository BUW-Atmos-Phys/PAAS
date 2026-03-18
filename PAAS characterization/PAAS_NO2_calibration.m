%% PAAS NO2 CALIBRATION ANALYSIS
clear; close all; clc;

%% CONFIGURATION
folder   = '/Users/emma/Documents/Instruments/PAAS/PAAS-4L-005/Characterisation/NO2 calibration/data/';
dataset_date = "2026-03-09";

do_phase_correction      = false;
phase_angle_target       = 225;

do_frequency_correction  = true;
select_periods_interactively = false;

%% Loaad json file
period_file  = 'calibration_periods.json';
db = jsondecode(fileread(period_file));
dataset_key = matlab.lang.makeValidName(dataset_date);
cfg = db.datasets.(dataset_key);

%% Load calibration data
paas = readtimetable(fullfile(folder,cfg.filename));

LockIn_phase_set = paas.Lockin_Phasing(1);

%% Remove points after laser switching
idx_change = find([false; diff(paas.Laser) ~= 0]);
idx_remove = unique([idx_change; idx_change+1; idx_change+2]);
idx_remove(idx_remove>height(paas)) = [];

paas(idx_remove,:) = [];

%% Optional phase correction
if do_phase_correction

    dphi = deg2rad(cfg.phase_angle_target - LockIn_phase_set);

    X_new = paas.X.*cos(dphi) - paas.Y.*sin(dphi);
    Y_new = paas.X.*sin(dphi) + paas.Y.*cos(dphi);

    paas.X = X_new;
    paas.Y = Y_new;

end

%% Interactive period picker (optional)
if select_periods_interactively

    figure
    plot(paas.TimeStamp,paas.R,'.-')
    grid on
    title('Click start/end pairs')

    n_bg   = input('Number of background periods: ');
    n_meas = input('Number of measurement periods: ');

    period_bg  = strings(n_bg,2);
    period_meas = strings(n_meas,2);

    disp('Select BACKGROUND periods')

    for i = 1:n_bg

        [x,~] = ginput(2);

        t1 = datetime(x(1),'ConvertFrom','datenum');
        t2 = datetime(x(2),'ConvertFrom','datenum');

        period_bg(i,:) = [string(t1),string(t2)];

    end

    disp('Select MEASUREMENT periods')

    for i = 1:n_meas

        [x,~] = ginput(2);

        t1 = datetime(x(1),'ConvertFrom','datenum');
        t2 = datetime(x(2),'ConvertFrom','datenum');

        period_meas(i,:) = [string(t1),string(t2)];

    end

    %% Save to JSON
    new_entry.filename = cfg.filename;
    new_entry.background = period_bg;
    new_entry.NO2_periods = period_meas;

    if isfile(cfg.period_file)

        db = jsondecode(fileread(cfg.period_file));

    else

        db.datasets = struct();

    end

    dataset_key = matlab.lang.makeValidName(cfg.dataset_date);
    db.datasets.(dataset_key) = new_entry;

    fid = fopen(cfg.period_file,'w');
    fprintf(fid,'%s',jsonencode(db,'PrettyPrint',true));
    fclose(fid);

    disp("Periods saved to JSON")

end

%% Load periods from JSON

% BG periods
n = numel(cfg.background);
BG_periods = NaT(n,2);
for i = 1:n
    
    pair = cfg.background{i};
    
    BG_periods(i,1) = datetime(pair{1});
    BG_periods(i,2) = datetime(pair{2});

end

% NO2 periods
n = numel(cfg.NO2_periods);
NO2_periods = NaT(n,2);
for i = 1:n
    
    pair = cfg.NO2_periods{i};
    
    NO2_periods(i,1) = datetime(pair{1});
    NO2_periods(i,2) = datetime(pair{2});

end

%% Split lasers automatically
unique_wl = unique(paas.Laser_WaveLength);
n_laser = numel(unique_wl);

for i = 1:n_laser
    laser_data{i} = paas(paas.Laser==(i-1),:);
end

%% Extract background data
for i = 1:n_laser

    T = laser_data{i};

    mask = T.TimeStamp > BG_periods(1,1) & ...
           T.TimeStamp < BG_periods(1,2);

    BG{i} = T(mask,:);

end

%% Extract measurement periods
n_periods = size(NO2_periods,1);

for p = 1:n_periods

    for i = 1:n_laser

        T = laser_data{i};

        mask = T.TimeStamp > NO2_periods(p,1) & ...
               T.TimeStamp < NO2_periods(p,2);

        period_data{i,p} = T(mask,:);

    end

end

%% Compute background corrected complex signal
for i = 1:n_laser

    bg = BG{i};

    BG_complex = mean(bg.X./bg.Power) + 1i*mean(bg.Y./bg.Power);

    for p = 1:n_periods

        T = period_data{i,p};

        S = mean(T.X./T.Power) + 1i*mean(T.Y./T.Power);

        S_corr(i,p) = abs(S - BG_complex);

    end

end

%% Gas properties
NO2_babs_1ppm = cfg.NO2_babs_1ppm;
bottle_conc   = cfg.bottle_conc;
total_flow    = cfg.total_flow;
flow_NO2      = cfg.NO2_flow;

NO2_conc = flow_NO2./total_flow .* bottle_conc;

%% Optional frequency correction
if do_frequency_correction

    datafolder   = '/Users/emma/Documents/Instruments/PAAS/PAAS-4L-005/Characterisation/Frequency scans/plots/';
    scan_files   = { ...
    'FreqScan_20260310_085649_405nm_05Hz.mat', ... % all-in-gas
    'FreqScan_20260310_091511_515nm_05Hz.mat', ... % all-in-gas
    'FreqScan_20260310_092258_405nm_05Hz.mat', ... % all-in-gas 
    'FreqScan_20260310_094218_405nm_05Hz.mat', ... % NO2 100%
    'FreqScan_20260310_095213_515nm_05Hz.mat', ... % NO2 100%
    'FreqScan_20260310_100956_405nm_05Hz.mat', ... % NO2 80%
    'FreqScan_20260310_101953_515nm_05Hz.mat' ... % NO2 80%
    };

    NO2_fraction = [0, 0, 0, 1, 1, 0.8, 0.8];  % corresponding NO2 fractions

    [C_fun,~] = compute_frequency_correction(datafolder,scan_files);
    [f0_fun,~,~] = compute_f0(datafolder,scan_files,NO2_fraction);

    f0 = f0_fun(flow_NO2./total_flow);

    C = C_fun(f0 - paas.Laser_Frequency(1));
    
    for i = 1:n_laser
        S_corr(i,:) = S_corr(i,:) .* C';
    end

end

%% Linear regression calibration
for i = 1:n_laser

    x = NO2_conc .* NO2_babs_1ppm(i);

    model{i} = fitlm(x,S_corr(i,:),'linear','intercept',true);

end

%% Plot calibration
for i = 1:n_laser

    figure
    hold on

    wl = unique_wl(i);

    color = wavelength2color(wl);

    x = NO2_conc .* NO2_babs_1ppm(i);

    a = scatter(x,S_corr(i,:),80,...
        'MarkerEdgeColor',color,...
        'MarkerFaceColor','w',...
        'LineWidth',1.5);

    x_fit = linspace(min(x),max(x)*1.3,200);

    intercept = model{i}.Coefficients(1,1).Estimate;
    slope     = model{i}.Coefficients(2,1).Estimate;

    b = plot(x_fit,intercept+slope*x_fit,...
        'Color',color,'LineWidth',2);

    xlabel('NO_2 absorption coefficient [m^{-1}]')
    ylabel('Laser power specific PA signal [V/W]')

    legend([a,b],{string(wl)+' nm','R='+string(intercept)+'+'+string(slope)+' b_{abs}'},'Location','southeast')

    grid on
    box on

    set(gca,'FontSize',15,'LineWidth',1.5)

    title(sprintf('Calibration %s  (%d nm)',dataset_date,wl))

end

%% FUNCTIONS

function [f0_fun,p,f0_arr] = compute_f0(datafolder,scan_files,NO2_fraction)

n_scans = length(scan_files);

f0_arr = zeros(n_scans,1);

for s = 1:n_scans

    load(fullfile(datafolder,scan_files{s}))

    f0_arr(s) = fit_parameters.f0;

end

p = polyfit(NO2_fraction(:),f0_arr,1);

f0_fun = @(x) polyval(p,x);

end


function [C_fun,C_unc] = compute_frequency_correction(datafolder,scan_files)

n_scans = length(scan_files);

df_all = [];

for s = 1:n_scans

    load(fullfile(datafolder,scan_files{s}))

    df_all = [df_all ; (f_fit - fit_parameters.f0)];

end

df_grid = linspace(min(df_all(:)),max(df_all(:)),500);

R_interp = nan(n_scans,length(df_grid));

for s = 1:n_scans

    load(fullfile(datafolder,scan_files{s}))

    df = f_fit - fit_parameters.f0;

    R_norm = R_fit./max(R_fit);

    R_interp(s,:) = interp1(df,R_norm,df_grid,'linear','extrap');

end

R_mean = mean(R_interp,1);
R_std  = std(R_interp,0,1);

C = 1./R_mean;

C_sigma = R_std./(R_mean.^2);

C_fun = @(df) interp1(df_grid,C,df,'linear','extrap');
C_unc = @(df) interp1(df_grid,C_sigma,df,'linear','extrap');

end