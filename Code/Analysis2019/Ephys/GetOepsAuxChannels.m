function [AuxData,TTLs] = GetOepsAuxChannels(myKsDir, BehaviorTrials, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('ADC', false, @(x) islogical(x) || x==0 || x==1);

% extract values from the inputParser
params.parse(varargin{:});
GetAux = params.Results.ADC;

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
    
    % ignore any transitions faster than 1 ms - behavior resolution is 2 ms
    temp(temp(:,3)<0.001,:) = [];
    TTLs.(char(Tags(i))) = temp;
end

%% mismatch between behavior and oeps trials
if any(abs(BehaviorTrials(1:5,3)-TTLs.Trial(1:5,3))>=0.01)
    % case 1 : behavior file has an extra trial
    if ~any(abs(BehaviorTrials(2:6,3)-TTLs.Trial(1:5,3))>=0.01)
        % append an extra NaN trial on the Oeps side
        TTLs.Trial = [NaN*TTLs.Trial(1,:); TTLs.Trial];

    % case 2 : behavior acq started mid-trial, first trial might be a bit shorter 
    elseif ~any(abs(BehaviorTrials(2:6,3)-TTLs.Trial(2:6,3))>=0.01)
        % do nothing
    end
end

%% find the odor ON time 
for i = 1:size(TTLs.Trial,1) % every trial
     % find the last odor valve ON transition just before this trial start
     if i > 1
         t1 = TTLs.Trial(i-1,2);
     else
         t1 = 0;
     end
     t2 = TTLs.Trial(i,1);
     
     ValveEvents = [];
     for thisOdor = 1:3
         myEvents = intersect(find(TTLs.(['Odor',num2str(thisOdor)])(:,1)>t1),...
             find(TTLs.(['Odor',num2str(thisOdor)])(:,1)<t2));
         myTimeStamps = TTLs.(['Odor',num2str(thisOdor)])(myEvents,:);
         ValveEvents = vertcat(ValveEvents,...
             [myTimeStamps thisOdor*ones(numel(myEvents),1)]);
     end
     if ~isempty(ValveEvents)
         [t3,x] = max(ValveEvents(:,1));
         TTLs.Trial(i,4:5) = [t2-t3 ValveEvents(x,4)];
     else
         TTLs.Trial(i,4:5) = [NaN 0];
     end
end

AuxData = [];
if GetAux
    %% Get analog/digital AuxData from Oeps files - for comparison with behavior data
    foo = dir(fullfile(myKsDir,'*_ADC1.continuous')); % pressure sensor
    filename = fullfile(myKsDir,foo.name);
    [Auxdata1, timestamps, ~] = load_open_ephys_data(filename); % data has channel IDs
    foo = dir(fullfile(myKsDir,'*_ADC2.continuous')); % thermistor
    filename = fullfile(myKsDir,foo.name);
    [Auxdata2, ~, ~] = load_open_ephys_data(filename); % data has channel IDs
    
    % adjust for clock offset between open ephys and kilosort
    timestamps = timestamps - offset;
    
    % downsample to behavior resolution
    
    AuxData(:,1) = 0:1/SampleRate:max(timestamps);
    AuxData(:,2) = interp1q(timestamps,Auxdata1,AuxData(:,1)); % pressure sensor
    AuxData(:,3) = interp1q(timestamps,Auxdata2,AuxData(:,1)); % thermistor
    % create a continuous TrialOn vector
    for MyTrial = 1:size(TTLs.Trial,1)
        [~,start_idx] = min(abs(AuxData(:,1)-TTLs.Trial(MyTrial,1)));
        [~,stop_idx]  = min(abs(AuxData(:,1)-TTLs.Trial(MyTrial,2)));
        AuxData(start_idx:stop_idx,4) = 1;
    end
end
end
