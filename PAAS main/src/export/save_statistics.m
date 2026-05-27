function save_statistics(TT_statistics, cfg, time_av, campaign)
%SAVE_STATISTICS Save timetable to .mat file with dynamic averaging name
%
%   save_statistics(TT_statistics, cfg, time_av)
%
%   time_av  → averaging time in hours (e.g. 3)
%   cfg.outputfolder_data → output directory

    % --- Check required field ---
    if ~isfield(cfg, 'outputfolder_data')
        error('cfg.outputfolder_data is missing');
    end

    % --- Ensure output folder exists ---
    if ~exist(cfg.outputfolder_data, 'dir')
        mkdir(cfg.outputfolder_data);
    end

    % --- Build filename ---
    filename = sprintf('%s_PAAS_statistics_%dh_average.mat', campaign, time_av);

    % --- Full path ---
    filepath = fullfile(cfg.outputfolder_data, filename);

    % --- Save ---
    save(filepath, 'TT_statistics');

    % --- Feedback ---
    fprintf('Saved TT_statistics (%dh average) to:\n%s\n', ...
        time_av, filepath);

end