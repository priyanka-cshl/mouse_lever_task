%% function to parse behavioral data from the mouse lever task
% into trials, with relevant continuous (lever, motor, respiration, lickpiezo)
% and event data (licks, target zone flags, odor ON-OFF, etc) for each trial

function [Traces, TrialInfo] = ParseBehavior(MyFilePath, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('plotsession', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('savesession', true, @(x) islogical(x) || x==0 || x==1);
params.addParameter('respiration', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('tuning', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('replay', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('spikes', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('photometry', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('chunksession', false, @(x) islogical(x) || x==0 || x==1);


% extract values from the inputParser
params.parse(varargin{:});
ReplotSession = params.Results.plotsession;
SaveSession = params.Results.savesession;
ChunkSession = params.Results.chunksession;
do_tuning = params.Results.tuning;
do_replay = params.Results.replay;
do_sniffs = params.Results.respiration;
do_spikes = params.Results.spikes;
do_photometry = params.Results.photometry;

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

%% core data extraction (and settings)
[MyData, MySettings, DataTags] = ReadSessionData(MyFilePath);
[FilePaths, MyFileName] = fileparts(MyFilePath);
disp(MyFileName);

%% replot the behavior session - GUI style
if ReplotSession
    RecreateSession(MyData);
end

%% Process sniff data
if do_sniffs
    RespData = MyData(:,15);
    %[sniff_stamps] = GetRespirationTimeStamps(RespData, 0.2, 1);
end

%% Parse into trials
[Trials] = CorrectMatlabSampleDrops(MyData, MySettings, DataTags);
[MyData, DataTags] = OdorLocationSanityCheck(MyData, DataTags);
[Traces, TrialInfo, TargetZones] = ParseBehavior2Trials(MyData, MySettings, DataTags, Trials);

%% Get info from the OEPS files if available
[myephysdir] = WhereSpikeFile(MyFileName);
% get all TTLs for the open ephys session
if do_spikes || do_replay
    [~,TTLs] = GetOepsAuxChannels(myephysdir, Trials.TimeStamps, 'ADC', 0);
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

%% Align replay and close loop trials using openephys triggers
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
    MyTuningTrials(165:end,:) = [];
    [EphysTuningTrials] = AlightPassiveTuningTrials(MyTuningTrials, TTLs, size(Trials.Indices,1));
    
    if ~isempty(EphysTuningTrials)
        PlotPassiveTuning(SingleUnits, EphysTuningTrials, MyTuningTrials, 'rasters', 1, 'psth',1,'whichunits', AllUnits);
    end    
    
    %         savepath = fullfile(FilePaths,'processed',filesep,MyFileName);
    %         save(strrep(savepath,'.mat','_processed.mat'),'Traces','TrialInfo',...
    %             'TargetZones','spiketimes','sessionstart','sessionstop');
end

end