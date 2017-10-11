function GenerateAllTFs(h)

% get all possible target levels
AllTargets = sort(h.target_level_array.Data);
AllTFs = zeros(h.TransferFunction.Data(1),numel(AllTargets));

for i = 1:numel(AllTargets)
    TargetDefinition.Data(2) = AllTargets(i);
    
    % readjust target zone upper and lower limits in proportion to the
    % partitioning of the available lever range
    total_range = h.TrialSettings.Data(1) - h.TrialSettings.Data(2);
    mywidth(1) = (h.TrialSettings.Data(1) - TargetDefinition.Data(2))/total_range;
    mywidth(2) = (TargetDefinition.Data(2) - h.TrialSettings.Data(2))/total_range;
    mywidth = 2*mywidth*h.ZoneLimitSettings.Data(1);
    
    % compute new target zone definition
    TargetDefinition.Data(1) = TargetDefinition.Data(2) + mywidth(1);
    TargetDefinition.Data(3) = TargetDefinition.Data(2) - mywidth(2);
    
    % compute TF
    target_limits = [h.TrialSettings.Data(2) TargetDefinition.Data(3:-1:1) h.TrialSettings.Data(1)];
    DAC_limits = h.DAC_levels.Data;
    Zone_limits = h.locations_per_zone.Data;
    [AllTFs(:,i)] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,h.TransferFunction.Data(1));
end

% reshape to get one long vector, get rid of negative values
TF = AllTFs(:) + 101;

sent = 0;
sending_attempts = 0;

%% send TF to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    
    h.Arduino.write(30,'uint16'); % handler code for transfer function update
    h.Arduino.write(length(TF),'uint16'); % tell Arduino the size of the TF vector
    % write the TF
    TF = uint16(TF);
    h.Arduino.write(TF', 'uint16');
    tic;
    while toc<5 && h.Arduino.Port.BytesAvailable<(2*length(TF+1))
    end
    % for every param Arduino writes back the param value
    if (h.Arduino.Port.BytesAvailable)>1
        TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        if length(TF_returned) >= length(TF)
            if all(TF_returned(1:end-1) == TF) && TF_returned(end) == 83
                disp(['arduino: transfer functions uploaded: attempts = ' num2str(sending_attempts+1)])
                sent = 1;
                h.TFupdate = 1;
                %update transfer function colormap
                TF = TF_4_plot;
                %h.TF_plot.CData = abs(TF(length(TF):-1:1))'/max(TF);
                h.TF_plot.CData = flipud(TF')/max(TF);
                h.all_locations.String = num2str(unique(TF)');
            else
                pause(.1);
                sending_attempts = sending_attempts + 1';
            end
        else
            pause(.1)
            sending_attempts = sending_attempts + 1';
        end
    else
        pause(.1)
        sending_attempts = sending_attempts+1';
    end
end

if sending_attempts == 9
    error('arduino: failed to upload transfer functions')
end
