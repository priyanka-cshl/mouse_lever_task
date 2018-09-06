function UpdateOdorVials(h)

sent = 0;
sending_attempts = 0;
for i = 1:4
    VialArray(i) = h.odor_vial.Value*~isempty(intersect(h.Odor_list.Value,i));
end
VialArray = uint16(VialArray);

while (sent == 0) && (sending_attempts <= 8)
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(55,'uint16'); % handler code for parameter update
    % write the params
    h.Arduino.write(VialArray, 'uint16');
    tic;
    while toc<0.5 && h.Arduino.Port.BytesAvailable<2*(length(VialArray)+1)
    end
    % for every param Arduino writes back the param value
    if (h.Arduino.Port.BytesAvailable)==2*(length(VialArray)+1)
        % read back the params that Arduino sent back
        params_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        if all(params_returned(1:end-1) == VialArray') && params_returned(end) == 51
            disp(['arduino: vials updated: attempts = ' num2str(sending_attempts+1),'; time = ',num2str(toc),' seconds'])
            sent = 1;            
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
    error('arduino: failed to update vials')
end