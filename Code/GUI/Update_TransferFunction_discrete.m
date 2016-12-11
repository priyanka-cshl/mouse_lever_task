function Update_TransferFunction_discrete(h)

% get current transfer function
target_limits = [h.TrialSettings.Data(2) h.TargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
DAC_limits = h.DAC_levels.Data;
Zone_limits = h.locations_per_zone.Data;
[TF] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,...
    h.TransferFunction.Data(1));

%update transfer function colormap
h.TF_plot.CData = abs(TF(length(TF):-1:1))'/max(TF);
% update plot height and position to match that of the lever graph
scalefactor = h.axes1.Position(4)/sum(abs(h.Plot_YLim.Data));
Y_position = h.axes1.Position(2) + scalefactor*abs(h.Plot_YLim.Data(1) - DAC_limits(1));
Height = scalefactor*abs(DAC_limits(2) - DAC_limits(1));
h.axes9.Position(2) = Y_position;
h.axes9.Position(4) = Height;

h.all_locations.String = num2str(unique(TF)');

TF = TF'+101; % get rid of negative values

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
    %if the write fails, Arduino writes back -1
    if (h.Arduino.Port.BytesAvailable)==0 % Arduino did not write back
        % write the TF
        TF = uint16(TF);
        h.Arduino.write(TF', 'uint16');
        pause(.05);
        % for every param Arduino writes back the param value
        if (h.Arduino.Port.BytesAvailable)>1
            TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
            if length(TF_returned) >= length(TF)
                if all(TF_returned(1:end-1) == TF) && TF_returned(end) == 83
                    disp(['arduino: transfer function updated: attempts = ' num2str(sending_attempts+1)])
                    sent = 1;
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
    else
        pause(.1)
        sending_attempts = sending_attempts+1';
    end
end


if sending_attempts == 9
    error('arduino: failed to update transfer function')
end

