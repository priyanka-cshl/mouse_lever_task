function [Arduino_Serial,port_num]= Start_Arduino_ArCOM(port_num)

% close any existing Serial communication tunnel 
try
    fclose(instrfind);
end

% find out which port Arduino is connected to
if nargin<1
    port_num = 5;
end
    
wrong_port = 1;
while wrong_port
    try 
        Arduino_Serial = ArCOMObject(['COM' num2str(port_num)], 115200); % Create and open the serial port
        wrong_port=0; % found the right one - exit while loop
    catch
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