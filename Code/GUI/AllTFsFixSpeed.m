function AllTFsFixSpeed(h)

% get all possible target levels
AllTargets = sort(h.target_level_array.Data);
AllTFs = zeros(h.TransferFunction.Data(1),numel(AllTargets));

for i = 1:numel(AllTargets)
    TargetDefinition.Data(1:3) = AllTargets(i) + [-0.4 0 0.4];
    % compute TF
    target_limits = [0.2 TargetDefinition.Data(3:-1:1) 4.8];
    [AllTFs(:,i)] = LeverTransferFunction_fixspeed(target_limits,h.MotorLocationsRange,h.TransferFunction.Data(1));   
end

AllTFs(AllTFs>h.MotorLocations) = h.MotorLocations;
AllTFs(AllTFs<-h.MotorLocations) = -h.MotorLocations;

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
