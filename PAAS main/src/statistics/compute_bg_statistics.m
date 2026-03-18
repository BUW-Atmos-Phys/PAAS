function [BG, stats] = compute_bg_statistics(paas, valve_functionality, time_av)

wavelength = unique(paas.Laser_WaveLength);
n_wl = length(wavelength);

BG = struct();

for i = 1:n_wl

    wl = wavelength(i);

    idx = paas.Relay1 == valve_functionality(1,1) & ...
          paas.Relay2 == valve_functionality(1,2) & ...
          paas.Laser_WaveLength == wl;

    time = paas.TimeStamp(idx);

    R = paas.R(idx);
    X = paas.X(idx);
    P = paas.Power(idx);
    f_g    = paas.Calibration_Gain(idx) ./ paas.Lockin_Gain(idx);
    C_cell = paas.Calbration_CellConstant(idx) ./ f_g;
    
    % absorption signals
    BG_R = R ./ P ./ C_cell;
    BG_X = X ./ P ./ C_cell;

    BG.(sprintf("BG_R_%d",wl)) = BG_R(1:end-1);
    BG.(sprintf("BG_X_%d",wl)) = BG_X(1:end-1);

    BG.(sprintf("diff_BG_R_%d",wl)) = diff(BG_R);
    BG.(sprintf("diff_BG_X_%d",wl)) = diff(BG_X);

    BG.(sprintf("Laser_Power_%d",wl)) = P(1:end-1);

    if i == 1
        BG.Time = time(1:end-1);
    end

end

% ------------------------------------------------
% create timetable
% ------------------------------------------------

BG_highres = timetable(BG.Time);

for i = 1:n_wl

    wl = wavelength(i);

    BG_highres.(sprintf("BG_R_%d",wl)) = BG.(sprintf("BG_R_%d",wl));
    BG_highres.(sprintf("BG_X_%d",wl)) = BG.(sprintf("BG_X_%d",wl));

    BG_highres.(sprintf("diff_BG_R_%d",wl)) = BG.(sprintf("diff_BG_R_%d",wl));
    BG_highres.(sprintf("diff_BG_X_%d",wl)) = BG.(sprintf("diff_BG_X_%d",wl));

    BG_highres.(sprintf("Laser_Power_%d",wl)) = BG.(sprintf("Laser_Power_%d",wl));

end

BG.BG_highres = BG_highres;

% ------------------------------------------------
% averaging
% ------------------------------------------------

if time_av > 0.5
    BG.BG_baseline = retime(BG_highres,'regular',...
        @(x) mean(x,'omitnan'),'TimeStep',hours(time_av));
else
    BG.BG_baseline = BG_highres;
end

BG.wavelength = wavelength;

% ------------------------------------------------
% Compute statistics
% ------------------------------------------------

for i = 1:n_wl

    wl = wavelength(i);

    xR = BG.BG_baseline.(sprintf("diff_BG_R_%d",wl));
    xX = BG.BG_baseline.(sprintf("diff_BG_X_%d",wl));

    stats.R.mean(i) = mean(xR,'omitnan');
    stats.R.std(i)  = std(xR,'omitnan');
    stats.R.rmse(i) = sqrt(mean(xR.^2,'omitnan'));
    stats.R.prctile(:,i) = prctile(xR,[25 75]);

    stats.X.mean(i) = mean(xX,'omitnan');
    stats.X.std(i)  = std(xX,'omitnan');
    stats.X.rmse(i) = sqrt(mean(xX.^2,'omitnan'));
    stats.X.prctile(:,i) = prctile(xX,[25 75]);

end

stats.wavelength = wavelength;

end