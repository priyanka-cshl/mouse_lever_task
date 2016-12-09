function [Arduino_Serial,port_num]= Start_Arduino(port_num)

% close any existing Serial communication tunnel 
try
    fclose(instrfind);
end

% find out which port Arduino is connected to
if nargin<1
    port_num = 4;
end
    
wrong_port = 1;
while wrong_port
    try 
        Arduino_Serial = serial(['COM' num2str(port_num)], 'BaudRate', 115200, 'DataBits', 8, 'StopBits', 1, 'Timeout', 1, 'DataTerminalReady', 'off');
        set(Arduino_Serial, 'OutputBufferSize', 8000);
        set(Arduino_Serial, 'InputBufferSize', 50000);
        fopen(Arduino_Serial);
        wrong_port=0; % found the right one - exit while loop
    catch
        delete(Arduino_Serial);
        clear Arduino_Serial
        wrong_port = 1 ; % to keep trying... 
        port_num = port_num + 1;
        try
            fclose(instrfind);
        end
    end
    if port_num == 22
        error('Arduino is not connected');
    end
end
end