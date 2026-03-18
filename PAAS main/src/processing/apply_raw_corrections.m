function paas = apply_raw_corrections(paas, cfg)
%APPLY_CORRECTIONS Apply campaign-specific corrections to raw data:
%   - phase angle rotation

    arguments
        paas table
        cfg struct
    end

    % -------------------------------------------------------------
    % Phase angle correction
    % -------------------------------------------------------------
    if isfield(cfg,"phase_angle_soll") && isfield(cfg,"phase_angle_soll_period")

        period = datetime(cfg.laser_power_corr_period, ...
                          "TimeZone", paas.TimeStamp.TimeZone);

        idx = paas.TimeStamp >= period(1) & paas.TimeStamp < period(2);

        if any(idx)
            dphi = deg2rad(cfg.phase_angle_soll(:) - paas.Lockin_Phasing);

            X_new =  paas.X.*cos(dphi) - paas.Y.*sin(dphi);
            Y_new =  paas.X.*sin(dphi) + paas.Y.*cos(dphi);

            paas.X = X_new;
            paas.Y = Y_new;

            fprintf("Phase angle was set to %.1f° for period %s to %s (%d timestamps).\n", ...
                cfg.phase_angle_soll, ...
                datestr(period(1)), ...
                datestr(period(2)), ...
                sum(idx));
        end
    end

end