function b_abs = apply_interlock_filter(b_abs, time, cfg)
%APPLY_INTERLOCK_FILTER Mask absorption during interlock failures

    arguments
        b_abs double
        time datetime
        cfg struct
    end

    if ~isfield(cfg,"interlock_failure_period") || ...
       ~isfield(cfg,"interlock_failure_laser")
        return
    end

    periods = cfg.interlock_failure_period;
    lasers  = cfg.interlock_failure_laser;

    for i = 1:size(periods,1)

        period = datetime(periods{i,:}, ...
                          "TimeZone", time.TimeZone);

        idx = time >= period(1) & time <= period(2);

        if any(idx)
            laser_id = lasers(i);

            if laser_id <= size(b_abs,1)
                b_abs(laser_id, idx) = NaN;

                fprintf("Interlock filter: Laser %d masked for %d timestamps.\n", ...
                        laser_id, sum(idx));
            end
        end
    end

end