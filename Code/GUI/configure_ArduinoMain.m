function [Arduino_Serial]=configure_ArduinoMain(handles)

% rig specific settings
switch char(handles.computername)
    case {'PRIYANKA-HP','JUSTINE'}
        DueCOMPort = 3;
        
    case 'PRIYANKA-PC'
        DueCOMPort = 4;
        
    case 'DESKTOP-05QAM9D'
        DueCOMPort = 3;
end

% initialize Arduino as Serial Object
[Arduino_Serial,portNum] = Start_Arduino_ArCOM(DueCOMPort);
pause(0.5);
Arduino_Serial.write(10, 'uint16'); % opening handshake - should return 5 as confirmation
tic
while (Arduino_Serial.Port.BytesAvailable == 0 && toc < 2)
end
if(Arduino_Serial.Port.BytesAvailable == 0)
    Arduino_Serial.close;
    error('arduino: arduino did not send confirmation byte in time')
end
if (Arduino_Serial.read(1, 'uint16')==5)
    disp(['arduino: connected on port COM' num2str(portNum)])
end
% discard any unread bytes on the port
if Arduino_Serial.Port.BytesAvailable > 0
    trash = Arduino_Serial.read(Arduino_Serial.Port.BytesAvailable, 'uint16');
end
clear trash

