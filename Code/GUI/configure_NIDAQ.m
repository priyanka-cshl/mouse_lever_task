function [NI_session, MFC_session, handles]=configure_NIDAQ(handles)

% rig specific settings
switch char(handles.computername)
    case {'marbprec', 'PRIYANKA-HP'}
        DeviceName = 'Dev2';
        handles.AnalogChannelNames = {'LeverDAC','LeverRaw','EncoderA','EncoderB','RespirationA','RespirationB'};
        AnalogChannelIDs = {'ai0','ai1','ai2','ai3','ai11','ai12'};
        handles.DigitalChannelNames = {'trial_on', 'in_target_zone', 'in_reward_zone', 'rewards', 'licks', 'homesensor'};
        DigitalChannelIDs = {'Port0/Line0:5'};
        % channel map for plotting 
        handles.trial_channel = 7;
        handles.reward_channel = 10;
        handles.lick_channel = 11;
        handles.homesensor_channel = 12;
        handles.MFCChannelNames = {'MFCAir','MFCOdor'};
        MFCSetPointChannelIDs = {'ai6','ai7'};
        MFCControlChannelIDs = {'ao0','ao1'};
        
    case 'PRIYANKA-PC'
        DeviceName = 'Dev2';
        handles.AnalogChannelNames = {'LeverDAC','LeverRaw','EncoderA','EncoderB','RespirationA','RespirationB'};
        AnalogChannelIDs = {'ai0','ai1','ai2','ai3','ai11','ai12'};
        handles.DigitalChannelNames = {'trial_on', 'in_target_zone', 'in_reward_zone', 'rewards', 'licks', 'homesensor'};
        DigitalChannelIDs = {'Port0/Line0:4'};
        handles.trial_channel = 7;
        handles.reward_channel = 10;
        handles.lick_channel = 11;
        handles.homesensor_channel = 12;
        handles.MFCChannelNames = {};
        MFCSetPointChannelIDs = {};
        MFCControlChannelIDs = {};
        
end

% configure NI DAQ
NI_session = daq.createSession('ni');
release(NI_session);
stop(NI_session);

% Configure Analog Channels
DAQchannels = addAnalogInputChannel(NI_session,DeviceName,AnalogChannelIDs,'Voltage');
for i = 1:size(AnalogChannelIDs,2)
    DAQchannels(i).TerminalConfig = 'SingleEnded';
    DAQchannels(i).Range = [-5 5];
end

% Configure Digital Channels
DAQchannels(i +(1:size(handles.DigitalChannelNames,2)) ) =  addDigitalChannel(NI_session,DeviceName,DigitalChannelIDs,'InputOnly');

i = size(handles.AnalogChannelNames,2) + size(handles.DigitalChannelNames,2);

if ~isempty(MFCSetPointChannelIDs)
    for j = 1:size(MFCSetPointChannelIDs,2)
        DAQchannels(i+j) = addAnalogInputChannel(NI_session,DeviceName,MFCSetPointChannelIDs(j),'Voltage');
        DAQchannels(i+j).TerminalConfig = 'SingleEnded';
        DAQchannels(i+j).Range = [-5 5];
    end
    handles.NIchannels = i+j;
else
    handles.NIchannels = i;
end

% set sampling rates
NI_session.Rate = handles.sampling_rate_array(1);
NI_session.DurationInSeconds = 60*60*3;
NI_session.NotifyWhenDataAvailableExceeds = handles.sampling_rate_array(1)/handles.sampling_rate_array(2);
% Hint : NotifyWhenDataAvailableExceeds fires the event DataAvailable which
% is linked to NI_Callback in the main start acquisition function

% configure NI DAQ - analog output for MFC control
if ~isempty(MFCSetPointChannelIDs)
    MFC_session = daq.createSession('ni');
    release(MFC_session);
    stop(MFC_session);
    addAnalogOutputChannel(MFC_session,DeviceName,MFCControlChannelIDs, 'Voltage');
else
    MFC_session = [];
end
