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
params.addParameter('spikes', false, @(x) islogical(x) || x==0 || x==1);

% extract values from the inputParser
params.parse(varargin{:});
ReplotSession = params.Results.plotsession;
SaveSession = params.Results.savesession;
do_spikes = params.Results.spikes;

%% Add relevant repositories
Paths = WhichComputer();
addpath(genpath(fullfile(Paths.Code,'open-ephys-analysis-tools')));

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
if ~exist(MyFilePath)
    foo = regexp(MyFilePath,'_','split');
    AnimalName = foo{1};
    SessionDate = foo{2};
    MyFilePath = fullfile(Paths.Grid.Behavior,AnimalName,MyFilePath);
    [FilePaths, MyFileName] = fileparts(MyFilePath);
else
    [FilePaths, MyFileName] = fileparts(MyFilePath);
    [~,AnimalName] = fileparts(FilePaths);
end
[MyData, MySettings, DataTags] = ReadSessionData(MyFilePath);
[FilePaths, MyFileName] = fileparts(MyFilePath);
disp(MyFileName);

%% replot the behavior session - GUI style
if ReplotSession
    RecreateSession(MyData);
end

%% Parse into trials
[Trials] = CorrectMatlabSampleDrops(MyData, MySettings, DataTags);
[MyData, DataTags] = OdorLocationSanityCheck(MyData, DataTags);
[Traces, TrialInfo, TargetZones] = ParseBehavior2Trials(MyData, MySettings, DataTags, Trials);

%% Check if passive tuning was done
MyTuningTrials = [];
[TuningFile] = WhereTuningFile(FilePaths,MyFileName);
if ~isempty(TuningFile)
    [MyTuningTrials, TrialSequence, ReplayTraces] = ParseTuningSession(TuningFile);
    disp(['Found Tuning File: ',TuningFile]);
end

%% Get info from the OEPS files if available
[myephysdir] = WhereSpikeFile(MyFileName,FilePaths); % returns empty if no recording file was found
TTLs = [];
if ~isempty(myephysdir)
    if size(myephysdir,1) == 1
        [TTLs,ReplayTTLs,TuningTTLs,~] = ...
            GetOepsAuxChannels(myephysdir, Trials.TimeStamps, MyTuningTrials, TrialSequence); % send 'ADC', 1 to also get analog aux data
    else
        while isempty(TTLs) && ~isempty(myephysdir)
            [TTLs,ReplayTTLs,TuningTTLs,~] = ...
                GetOepsAuxChannels(myephysdir(1,:), Trials.TimeStamps, MyTuningTrials, TrialSequence);
            if isempty(TTLs)
                myephysdir(1,:) = [];
            end
        end
    end
end

if isempty(TTLs)
    disp('no matching recording file found');
end

%% Get spikes - label spikes by trials
if do_spikes && ~isempty(TTLs)
    SingleUnits = GetSingleUnits(myephysdir);
    [SingleUnits] = Spikes2Trials(SingleUnits, TTLs.Trial(1:size(TrialInfo.TrialID,2),:), ...
        ReplayTTLs, TuningTTLs);
    
%     % keep only good units
%     GoodUnits = [];
%     for i = 1:size(SingleUnits,2)
%         if SingleUnits(i).quality == 1
%             GoodUnits = [GoodUnits i];
%         end
%     end
%     AllUnits = [1:i];
%     disp(['found ',num2str(numel(GoodUnits)),' good units']);
%     GoodUnits
%     
%     PlotUnits = [6 8 40 48 50]; % O3
%     PlotUnits = [4 39 43 44 16]; % PCX4
%     % plot all single units 
%     RecordingSessionOverview(SingleUnits);
    
else
    SingleUnits = [];
end

%% Process replay trials
if any(strcmp(TrialInfo.Perturbation,'OL-Template'))
    [OpenLoop] = ExtractReplayTrials(Traces, TrialInfo, TTLs, ReplayTTLs);
    %[OpenLoop] = ParseReplayTrials(Traces, TrialInfo, TTLs, ReplayTTLs);
    ProcessOpenLoopTrials(OpenLoop, TrialInfo, SingleUnits, TTLs, ...
        'plotfigures', 1, 'whichunits', PlotUnits);
end

if do_spikes && do_tuning
    %% get Spikes    
    if ~isempty(EphysTuningTrials)
        PlotPassiveTuning(SingleUnits, TuningTTLs, MyTuningTrials, 'rasters', 1, 'psth',1,'whichunits', PlotUnits);
    end    
end

    %         savepath = fullfile(FilePaths,'processed',filesep,MyFileName);
    %         save(strrep(savepath,'.mat','_processed.mat'),'Traces','TrialInfo',...
    %             'TargetZones','spiketimes','sessionstart','sessionstop');
    
end