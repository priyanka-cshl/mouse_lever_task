function [NI_session,Arduino_Serial,MFC_session,Odor_session]=configure_NI_and_Arduino_ArCOM(handles)

%% ------------------------------------------------------------------------------------------------------------
% configure NI DAQ
NI_session = daq.createSession('ni');
release(NI_session);
stop(NI_session);

% configure analog channels (4)
if  strcmp(handles.computername,'PRIYANKA-PC')
    DAQchannels = addAnalogInputChannel(NI_session,'Dev2',{'ai0','ai1','ai2','ai3','ai11','ai12'},'Voltage');
end
% configure all analog channels as single ended and voltage range [-5 to 5]
for i = 1:4
    DAQchannels(i).TerminalConfig = 'SingleEnded';
    DAQchannels(i).Range = [-5 5];
end
% configure respiration channels as -10 to 10 V
for i = 5:6
    DAQchannels(i).TerminalConfig = 'SingleEnded';
    DAQchannels(i).Range = [-10 10];
end
% configure digital channels
for i = handles.NIchannels-4:handles.NIchannels
    DAQchannels(i)= addDigitalChannel(NI_session,'Dev2',['Port0/Line',num2str(i-(handles.NIchannels-4))],'InputOnly');
end

% configure MFC channels (2)
for j = 1:4
    DAQchannels(i+j) = addAnalogInputChannel(NI_session,'Dev2',{['ai',num2str(3+j)]},'Voltage');
    DAQchannels(i+j).TerminalConfig = 'SingleEnded';
    DAQchannels(i+j).Range = [-5 5];
end

% set sampling rates
NI_session.Rate = handles.sampling_rate_array(1);
NI_session.DurationInSeconds = 60*60*3;
NI_session.NotifyWhenDataAvailableExceeds = handles.sampling_rate_array(1)/handles.sampling_rate_array(2);
% Hint : NotifyWhenDataAvailableExceeds fires the event DataAvailable which
% is linked to NI_Callback in the main start acquisition function

%% ------------------------------------------------------------------------------------------------------------
% configure NI DAQ - analog output
MFC_session = daq.createSession('ni');
release(MFC_session);
stop(MFC_session);
addAnalogOutputChannel(MFC_session,'cDAQ1Mod1', 0, 'Voltage');
addAnalogOutputChannel(MFC_session,'cDAQ1Mod1', 2, 'Voltage');
addAnalogOutputChannel(MFC_session,'cDAQ1Mod1', 4, 'Voltage');
addAnalogOutputChannel(MFC_session,'cDAQ1Mod1', 6, 'Voltage');
%% ------------------------------------------------------------------------------------------------------------

%% ------------------------------------------------------------------------------------------------------------
% configure NI DAQ - digital output (valves)
Odor_session = daq.createSession('ni');
release(Odor_session);
stop(Odor_session);
addDigitalChannel(Odor_session,'Dev2','Port0/Line5','OutputOnly');
addDigitalChannel(Odor_session,'Dev2','Port0/Line6','OutputOnly');
addDigitalChannel(Odor_session,'Dev2','Port0/Line7','OutputOnly');
%addDigitalChannel(Odor_session,'Dev2','Port1/Line0','OutputOnly');
%% ------------------------------------------------------------------------------------------------------------

%% ------------------------------------------------------------------------------------------------------------
% initialize Arduino as Serial Object
[Arduino_Serial,portNum] = Start_Arduino_ArCOM(30);
pause(5);
Arduino_Serial.write(10, 'uint16'); % opening handshake - should return 5 as confirmation
%Arduino_Serial.Port.BytesAvailable
tic
while (Arduino_Serial.Port.BytesAvailable == 0 && toc < 2)
end
if(Arduino_Serial.Port.BytesAvailable == 0)
    Arduino_Serial.close;%fclose(instrfind);
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

