function paas = load_raw_data(cfg)
%LOAD_RAW_DATA  Load and concatenate all raw PAAS CSV files
%
%   paas = LOAD_RAW_DATA(cfg)
%
%   Requires:
%       cfg.datafolder
%       cfg.n_laser
%       cfg.BG
%
%   Returns:
%       paas  -> concatenated table

    arguments
        cfg struct
    end

    if ~isfolder(cfg.datafolder)
        error("Data folder does not exist: %s", cfg.datafolder);
    end

    files = dir(fullfile(cfg.datafolder, "*.csv"));

    if isempty(files)
        error("No CSV files found in %s", cfg.datafolder);
    end

    fprintf("Loading %d files from %s\n", length(files), cfg.datafolder);

    paas = table();

    for i = 1:length(files)

        filename = fullfile(files(i).folder, files(i).name);
        fprintf("  Reading %s\n", files(i).name);

        % --- Import PAAS data
        dummy = import_PAAS(filename, cfg.n_laser, cfg.BG, false);

        % --- Append
        paas = [paas; dummy];

    end

    % --- Sort by time if TimeStamp exists
    if ismember("TimeStamp", paas.Properties.VariableNames)
        paas = sortrows(paas, "TimeStamp");
    end

    fprintf("Finished loading raw data.\n");

end