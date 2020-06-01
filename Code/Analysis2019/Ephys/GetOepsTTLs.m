function [TTLs] = GetOepsTTLs(myKsDir, TS)

if nargin<2
    TS = [];
end

%% add the relevant repositories to path
addpath(genpath('/opt/open-ephys-analysis-tools'))

%% defaults
sampleRate = 30000; % Open Ephys acquisition rate


%% Filepaths
% myKsDir = '/mnt/analysis/N8/2019-01-26_19-24-28'; % directory with kilosort output

%% Get Trial Timestamps from the OpenEphys Events file
filename = fullfile(myKsDir,'all_channels.events');
[data, timestamps, info] = load_open_ephys_data(filename); % data has channel IDs

% adjust for clock offset between open ephys and kilosort
[offset] = AdjustClockOffset(myKsDir);
offset = offset/sampleRate;
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

%% Match Trial Events to Behavior file
% Hack - sometimes the first trial is not registered in the behavior file
if ~isempty(TS)
    while abs(TTLs.Trial(1,3)-TS(1,3))>0.002
        TTLs.Trial(1,:) = [];
    end
end

end
