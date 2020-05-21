function [AuxData,TTLs,BehaviorOffset] = GetOepsAuxChannels(myKsDir, trialstart)

if nargin<2
    trialstart = 0; % timestamp at which first trial starts in the behavior file
end

%% add the relevant repositories to path
addpath(genpath('/opt/open-ephys-analysis-tools'))

%% defaults
OepsSampleRate = 30000; % Open Ephys acquisition rate
global SampleRate; % Behavior Acquisition rate

%% Filepaths
% myKsDir = '/mnt/analysis/N8/2019-01-26_19-24-28'; % directory with kilosort output

%% Get Trial Timestamps from the OpenEphys Events file
filename = fullfile(myKsDir,'all_channels.events');
[data, timestamps, info] = load_open_ephys_data(filename); % data has channel IDs

% adjust for clock offset between open ephys and kilosort
[offset] = AdjustClockOffset(myKsDir);
offset = offset/OepsSampleRate;
timestamps = timestamps - offset;

% Get various events
TTLTypes = unique(data);
Tags = {'Air', 'Odor1', 'Odor2', 'Odor3', 'Trial', 'Reward'};
for i = 1:numel(TTLTypes)
    On = timestamps(intersect(find(info.eventId),find(data==TTLTypes(i))));
    Off = timestamps(intersect(find(~info.eventId),find(data==TTLTypes(i))));
    % delete the first off value, if it preceeds the On
    Off(Off<On(1)) = [];
    On(On>Off(end)) = [];
    temp = [On Off Off-On];
    % ignore any transitions faster than 0.5 ms - behavior resolution is 2 ms
    temp(temp(:,3)<0.0005,:) = [];
    TTLs.(char(Tags(i))) = temp;
end

% match timestamps to behavior acquisition start
OepsTrialStart = TTLs.Trial(2,1); % second trial
% make this the same value as TrialStart in Behvaior
BehaviorOffset = trialstart - OepsTrialStart;
for i = 1:numel(TTLTypes)
    TTLs.(char(Tags(i)))(:,1:2) = TTLs.(char(Tags(i)))(:,1:2) + BehaviorOffset;
end

%% Get analog/digital AuxData from Oeps files - for comparison with behavior data
foo = dir(fullfile(myKsDir,'*_ADC1.continuous')); % pressure sensor
filename = fullfile(myKsDir,foo.name);
[Auxdata1, timestamps, ~] = load_open_ephys_data(filename); % data has channel IDs
foo = dir(fullfile(myKsDir,'*_ADC2.continuous')); % thermistor
filename = fullfile(myKsDir,foo.name);
[Auxdata2, ~, ~] = load_open_ephys_data(filename); % data has channel IDs

% adjust for clock offset between open ephys and kilosort
timestamps = timestamps - offset;
% adjust for behavior offset
timestamps = timestamps + BehaviorOffset;

% downsample to behavior resolution
AuxData = [];
AuxData(:,1) = 1/SampleRate:1/SampleRate:max(timestamps);
AuxData(:,2) = interp1q(timestamps,Auxdata1,AuxData(:,1)); % pressure sensor
AuxData(:,3) = interp1q(timestamps,Auxdata2,AuxData(:,1)); % thermistor
% create a continuous TrialOn vector
for MyTrial = 1:size(TTLs.Trial,1)
    [~,start_idx] = min(abs(AuxData(:,1)-TTLs.Trial(MyTrial,1)));  
    [~,stop_idx]  = min(abs(AuxData(:,1)-TTLs.Trial(MyTrial,2)));
    AuxData(start_idx:stop_idx,4) = 1;
end

end
