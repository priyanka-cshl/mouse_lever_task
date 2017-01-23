function Update_TransferFunction_discrete(h)

% which TF?
my_target_levels = sort(h.target_level_array.Data);
which_TF = find(my_target_levels==h.TargetDefinition.Data(2),1);
highlim = h.TargetDefinition.Data(1);
lowlim = h.TargetDefinition.Data(3);

%% convert highlim, lowlim voltage values to int16 range before sending
voltage_to_int = round(inv(h.DAC_levels.Data(2)/(2^16)));
highlim = round(highlim*voltage_to_int);
if highlim>2^16-1
    highlim = 2^16-1;
end
lowlim = round(lowlim*voltage_to_int);
if lowlim>2^16-1
    lowlim = 2^16-1;
end

%update transfer function colormap
TF = h.(['TF',num2str(which_TF)]);
h.TF_plot.CData = abs(TF(length(TF):-1:1))'/max(TF);
% update plot height and position to match that of the lever graph
scalefactor = h.axes1.Position(4)/sum(abs(h.Plot_YLim.Data));
DAC_limits = h.DAC_levels.Data;
Y_position = h.axes1.Position(2) + scalefactor*abs(h.Plot_YLim.Data(1) - DAC_limits(1));
Height = scalefactor*abs(DAC_limits(2) - DAC_limits(1));
h.axes9.Position(2) = Y_position;
h.axes9.Position(4) = Height;
h.all_locations.String = num2str(unique(TF)');

sent = 0;
sending_attempts = 0;

%% send TF to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(50,'uint16'); % handler code for current transfer function update
    %if the write fails, Arduino writes back -1
    if (h.Arduino.Port.BytesAvailable)==0 % Arduino did not write back
        h.Arduino.write(which_TF,'uint16');
        h.Arduino.write(highlim,'uint16');
        h.Arduino.write(lowlim,'uint16');
        pause(.05);
        % for every param Arduino writes back the param value
        if (h.Arduino.Port.BytesAvailable)>1
            TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
            if length(TF_returned) >= 3
                if all(TF_returned(1:end-1) == [which_TF highlim lowlim]') && TF_returned(end) == 83
                    disp(['arduino: target zone updated: attempts = ' num2str(sending_attempts+1)])
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
    error('arduino: failed to update target zone')
end

