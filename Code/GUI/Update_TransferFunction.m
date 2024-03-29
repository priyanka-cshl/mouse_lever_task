function Update_TransferFunction(h, whichcase)

% get current transfer function
%target_limits = [h.TrialSettings.Data(2) h.NewTargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
target_limits = [h.TrialSettings.Data(2) h.TargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
DAC_limits = h.DAC_levels.Data;
Zone_limits = h.locations_per_zone.Data;
switch whichcase
    case 0
        [TF] = LeverTransferFunction_fixspeed(target_limits,h.MotorLocationsRange,...
            h.TransferFunction.Data(1));
    case 1
        [TF] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,...
            h.TransferFunction.Data(1));
end

TF(TF>h.MotorLocations) = h.MotorLocations;
TF(TF<-h.MotorLocations) = -h.MotorLocations;

if ~h.current_trial_block.Data(1)
    TF = -TF; % invert the TF
end

TF_4_plot = TF; % use later for colormap update

TF = TF'+ h.MotorLocations + 1; % get rid of negative values % transform to a column vector
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
    while toc<0.5 && h.Arduino.Port.BytesAvailable<2*(length(TF)+1)
    end
    % for every param Arduino writes back the param value
    if (h.Arduino.Port.BytesAvailable)==2*(length(TF)+1)
        TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        if all(TF_returned(1:end-1) == TF) && TF_returned(end) == 83
            disp(['arduino: transfer function updated: attempts = ' num2str(sending_attempts+1),'; time = ',num2str(toc),' seconds'])
            sent = 1;
            h.TFupdate = 1;
            %update transfer function colormap
            TF = TF_4_plot;
            %h.TF_plot.CData = abs(TF(length(TF):-1:1))'/max(TF);
            %h.TF_plot.CData = flipud(TF')/max(TF);
            h.TF_plot.CData = flipud(TF')/h.MotorLocations;
            %h.all_locations.String = num2str(unique(TF)');
            h.all_locations.String = num2str((-h.MotorLocations:1:h.MotorLocations)');
        else
            pause(.1);
            sending_attempts = sending_attempts + 1';
        end
    else
        pause(.1)
        sending_attempts = sending_attempts+1';
    end
end

if sending_attempts == 9
    error('arduino: failed to update transfer function')
end
