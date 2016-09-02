function [NI_session,Arduino_Serial]=configure_NI_and_Arduino(handles)

%% ------------------------------------------------------------------------------------------------------------
% configure NI DAQ
NI_session = daq.createSession('ni');
release(NI_session);
stop(NI_session);

% configure analog channels (4)
if  strcmp(handles.computername,'PRIYANKA-PC')
    DAQchannels = addAnalogInputChannel(NI_session,'Dev2',{'ai0','ai1','ai2','ai3'},'Voltage');
end
% configure all analog channels as single ended and voltage range [-5 to 5]
for i = 1:4
    DAQchannels(i).TerminalConfig = 'SingleEnded';
    DAQchannels(i).Range = [-5 5];
end

% configure digital channels
for i = handles.NIchannels-4:handles.NIchannels
    DAQchannels(i)= addDigitalChannel(NI_session,'Dev2',['Port0/Line',num2str(i-5)],'InputOnly');
end

% set sampling rates
NI_session.Rate = handles.sampling_rate_array(1);
NI_session.DurationInSeconds = 60*60*3;
NI_session.NotifyWhenDataAvailableExceeds = handles.sampling_rate_array(1)/handles.sampling_rate_array(2);
% Hint : NotifyWhenDataAvailableExceeds fires the event DataAvailable which
% is linked to NI_Callback in the main start acquisition function

%% ------------------------------------------------------------------------------------------------------------
% initialize Arduino as Serial Object
[Arduino_Serial,portNum] = Start_Arduino;
fwrite(Arduino_Serial, char(50)); % opening handshake - should return 5 as confirmation
set(Arduino_Serial, 'RequestToSend', 'on');
tic
while (Arduino_Serial.BytesAvailable == 0 && toc < 2)
end
if(Arduino_Serial.BytesAvailable == 0)
    error('arduino: arduino did not send confirmation byte in time')
end
fread(Arduino_Serial, Arduino_Serial.BytesAvailable);
set(Arduino_Serial, 'RequestToSend', 'off')
disp(['arduino: connected on port COM' num2str(portNum)])
% discard any unread bytes on the port
if Arduino_Serial.BytesAvailable > 0
    trash = fread(Arduino_Serial, Arduino_Serial.BytesAvailable)
end
clear trash

