function cfg = get_instrument_config(inst, camp)

% --- Load scientific config
C = load_json("config/instrument_config.json");

% --- Load local config
L = load_json("config/local_config.json");

% --- Extract scientific parameters
cfg = C.(inst).(camp);

% --- Extract local parameters
local = L.(inst).(camp);

% --- Build paths
cfg.datafolder   = fullfile(local.data_root, local.data_subfolder);
cfg.outputfolder_plots = fullfile(local.output_root_plots);
cfg.outputfolder_data = fullfile(local.output_root_data);

end


function S = load_json(filename)
    fid = fopen(filename);
    raw = fread(fid, inf);
    fclose(fid);
    S = jsondecode(char(raw'));
end