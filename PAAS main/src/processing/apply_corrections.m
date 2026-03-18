function b_abs = apply_corrections(b_abs, time, cfg)
%APPLY_CORRECTIONS Apply campaign-specific corrections to:
%   - laser power measurements
%   - cell constant

    arguments
        b_abs double
        time datetime
        cfg struct
    end

    n_time = numel(time);

    % -------------------------------------------------------------
    % Laser power correction
    % -------------------------------------------------------------
    if isfield(cfg,"laser_power_corr") && isfield(cfg,"laser_power_corr_period")

        period = datetime(cfg.laser_power_corr_period, ...
                          "TimeZone", time.TimeZone);

        idx = time >= period(1) & time < period(2);

        if any(idx)
            corr_vec = cfg.laser_power_corr(:); % column vector
            b_abs(:,idx) = b_abs(:,idx) .* corr_vec;

            fprintf("Laser power correction applied to %d timestamps.\n", sum(idx));
        end
    end

    % -------------------------------------------------------------
    % Calibration correction (cell constant)
    % -------------------------------------------------------------
    if isfield(cfg,"calibration_corr") && isfield(cfg,"calibration_corr_period")

        period = datetime(cfg.calibration_corr_period, ...
                          "TimeZone", time.TimeZone);

        idx = time >= period(1) & time < period(2);

        if any(idx)
            b_abs(:,idx) = b_abs(:,idx) * cfg.calibration_corr;

            fprintf("Calibration correction applied to %d timestamps.\n", sum(idx));
        end
    end

end