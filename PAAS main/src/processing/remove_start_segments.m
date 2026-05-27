function paas = remove_start_segments(paas, valve_functionality)
% When the program is started both Relays are open 
% Relay1 == 0 & Relay2 == 0
% This function removes these entries and all following entries before the
% first background

    % Define states
    is_zero = paas.Relay1 == 0 & paas.Relay2 == 0;

    is_bg = paas.Relay1 == valve_functionality(1,1) & ...
            paas.Relay2 == valve_functionality(1,2);

    % Initialize
    keep = true(height(paas),1);
    in_invalid = false;

    for i = 1:height(paas)

        if ~in_invalid
            % Enter invalid block
            if is_zero(i)
                in_invalid = true;
                keep(i) = false;
            end
        else
            % Stay invalid until BG is reached
            keep(i) = false;

            if is_bg(i)
                in_invalid = false; % exit invalid block
                keep(i) = true;     % keep the first valid BG again
            end
        end

    end

    % Apply mask
    paas = paas(keep,:);

end