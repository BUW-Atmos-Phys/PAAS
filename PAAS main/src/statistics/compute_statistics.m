function TT_statistics = compute_statistics(time, b_abs, laser_wavelength, time_av)
%COMPUTE_STATISTICS Compute time-averaged statistics per wavelength
%
% INPUT:
%   time              datetime vector (1 x N or N x 1)
%   b_abs             [n_laser x N] absorption matrix
%   laser_wavelength  vector [n_laser]
%   time_av           averaging window in hours (scalar)
%
% OUTPUT:
%   TT_statistics     timetable with mean, std, median, percentiles, min, max

    arguments
        time datetime
        b_abs double
        laser_wavelength double
        time_av double {mustBePositive}
    end

    % Ensure column time vector
    time = time(:);

    n_laser = size(b_abs,1);

    if length(laser_wavelength) ~= n_laser
        error("laser_wavelength length must match number of rows in b_abs.");
    end

    TT_statistics = timetable();

    for i = 1:n_laser

        % --------------------------------------------
        % Build timetable for single wavelength
        % --------------------------------------------
        tt = timetable(time, b_abs(i,:).');

        % --------------------------------------------
        % Compute statistics
        % --------------------------------------------
        timestep = hours(time_av);

        tt_mean   = retime(tt, 'regular', @(x) mean(x,'omitnan'),  'TimeStep', timestep);
        tt_std    = retime(tt, 'regular', @(x) std(x,'omitnan'),   'TimeStep', timestep);
        tt_median = retime(tt, 'regular', @(x) median(x,'omitnan'),'TimeStep', timestep);
        tt_prctl  = retime(tt, 'regular', @(x) prctile(x,[25 75]), 'TimeStep', timestep);
        tt_min    = retime(tt, 'regular', 'min',                   'TimeStep', timestep);
        tt_max    = retime(tt, 'regular', 'max',                   'TimeStep', timestep);
        tt_n      = retime(tt, 'regular', @(x) sum(~isnan(x)), 'TimeStep', timestep);

        % Calculate statistical uncertainty
        tt_sem = tt_std;
        for v = tt_std.Properties.VariableNames
            tt_sem.(v{1}) = tt_std.(v{1}) ./ sqrt(tt_n.(v{1}));
        end

        % --------------------------------------------
        % Assemble per-wavelength timetable
        % --------------------------------------------
        wl = num2str(laser_wavelength(i));
        
        tt_wl = timetable(tt_mean.time, ...
                          tt_mean.Var1, ...
                          tt_std.Var1, ...
                          tt_sem.Var1, ...
                          tt_median.Var1, ...
                          tt_prctl.Var1(:,1), ...
                          tt_prctl.Var1(:,2), ...
                          tt_min.Var1, ...
                          tt_max.Var1, ...
                          'VariableNames', { ...
                              ['mean_' wl], ...
                              ['std_' wl], ...
                              ['sem_' wl], ...
                              ['median_' wl], ...
                              ['prct25_' wl], ...
                              ['prct75_' wl], ...
                              ['min_' wl], ...
                              ['max_' wl]});

        % --------------------------------------------
        % Synchronize across wavelengths
        % --------------------------------------------
        if isempty(TT_statistics)
            TT_statistics = tt_wl;
        else
            TT_statistics = synchronize(TT_statistics, tt_wl, 'union');
        end

    end

    fprintf("Statistics computed (%d h averaging, %d wavelengths).\n\n", ...
            time_av, n_laser);

end