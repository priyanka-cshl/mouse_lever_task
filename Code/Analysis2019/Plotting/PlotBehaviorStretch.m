%% function to parse behavioral data from the mouse lever task
% into trials, with relevant continuous (lever, motor, respiration, lickpiezo)
% and event data (licks, target zone flags, odor ON-OFF, etc) for each trial

function [Traces, TrialInfo] = PlotBehaviorStretch(MyFilePath, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('timestamps', [], @(x) isnumeric(x));
params.addParameter('trials', [], @(x) isnumeric(x));

% extract values from the inputParser
params.parse(varargin{:});
TimeStamps = params.Results.timestamps;
TrialIdx = params.Results.trials;

%% globals
% global MyFileName;
global SampleRate;
SampleRate = 500; % Samples/second
global startoffset;
startoffset = 1; % in seconds
global savereplayfigs;
savereplayfigs = 0;
global whichreplay;
global errorflags; % [digital-analog sample drops, timestamp drops, RE voltage drift, motor slips]
errorflags = [0 0 0 0];
global TargetZones;

%% core data extraction (and settings)
[MyData, MySettings, DataTags] = ReadSessionData(MyFilePath);
%% Parse into trials
[Trials] = CorrectMatlabSampleDrops(MyData, MySettings, DataTags);
[MyData, DataTags] = OdorLocationSanityCheck(MyData, DataTags);
[Traces, TrialInfo, TargetZones] = ParseBehavior2Trials(MyData, MySettings, DataTags, Trials);

% extract the relevant stretch of data
if isempty(TrialIdx) & ~isempty(TimeStamps)
    % get the relevant TrialIdx
    TrialIdx = [find(TrialInfo.SessionTimestamps(:,1)>=TimeStamps(1),1,'first'): ...
        find(TrialInfo.SessionTimestamps(:,1)>=TimeStamps(2),1,'first')-1];
    
end

% %% replot the behavior session - GUI style
% if ReplotSession
%     RecreateSession(MyData);
% end




%% Process replay trials
if any(strcmp(TrialInfo.Perturbation,'OL-Template'))
    [OpenLoop] = ParseReplayTrials(Traces, TrialInfo, TTLs, ReplayTTLs);
    ProcessOpenLoopTrials(OpenLoop, TrialInfo, [], TTLs, 'plotfigures',1);
    %ProcessReplayTrials(Replay, TrialInfo, TargetZones, SingleUnits, TTLs, 'plotfigures',1, 'whichunits', [13 17 18 19 20]);
end

% Align replay and close loop trials using openephys triggers
if do_replay && any(diff(MySettings(:,32))== 2) && ~isempty(WhereSpikeFile(MyFileName))
    % Split the long replay trial in the behavior file
    % into individual trials using the Odor TTls in the Oeps file
    if ~isempty(TTLs)
    [Replay, TTLs] = ParseReplayTrials(MyData, MySettings, DataTags, TrialInfo, TTLs);
    whichreplay = 1;
    %PlotReplayTrials(Replay, TrialInfo, TargetZones, SingleUnits, TTLs);
    [Behavior, Ephys] = ProcessReplayTrials(Replay, TrialInfo, TargetZones, SingleUnits, TTLs, 'plotfigures',1, 'whichunits', [13 17 18 19 20]);
    else
        disp('No Oeps File found: Cannot process replay sessions!');
    end
    
end

%% Get spikes - label spikes by trials
if do_spikes
    SingleUnits = GetSingleUnits(myephysdir);
    [SingleUnits] = Spikes2Trials(TTLs, SingleUnits);
    %[SingleUnits, EphysTuningTrials] = Spikes2Trials_Tuning(myephysdir, TS, TrialInfo, MyTuningTrials);
    
    % keep only good units
    GoodUnits = [];
    for i = 1:size(SingleUnits,2)
        if SingleUnits(i).quality == 1
            GoodUnits = [GoodUnits i];
        end
    end
    AllUnits = [1:i];
    disp(['found ',num2str(numel(GoodUnits)),' good units']);
    GoodUnits
else
    SingleUnits = [];
end

if do_tuning
    [TuningFile] = WhereTuningFile(FilePaths,MyFileName);
    if ~isempty(TuningFile)
        [MyTuningData, MyTuningSettings, MyTuningTrials] = ExtractTuningSession(TuningFile);
        disp(['Loaded Tuining File: ',TuningFile]);
    else
        MyTuningTrials = [];
    end
end

if do_spikes && do_tuning
    %% get Spikes    
    if ~isempty(EphysTuningTrials)
        PlotPassiveTuning(SingleUnits, TuningTTLs, MyTuningTrials, 'rasters', 1, 'psth',1,'whichunits', AllUnits);
    end    
    
    %         savepath = fullfile(FilePaths,'processed',filesep,MyFileName);
    %         save(strrep(savepath,'.mat','_processed.mat'),'Traces','TrialInfo',...
    %             'TargetZones','spiketimes','sessionstart','sessionstop');
end

end