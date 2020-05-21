%% function to parse behavioral data from the mouse lever task
% into trials, with relevant continuous (lever, motor, respiration, lickpiezo)
% and event data (licks, target zone flags, odor ON-OFF, etc) for each trial

function [Traces, TrialInfo, TargetZones, spiketimes] = ParseBehaviorAndPhysiology(MyFilePath, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('plotsession', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('respiration', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('tuning', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('replay', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('spikes', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('photometry', false, @(x) islogical(x) || x==0 || x==1);

% extract values from the inputParser
params.parse(varargin{:});
ReplotSession = params.Results.plotsession;
do_tuning = params.Results.tuning;
do_replay = params.Results.replay;
do_sniffs = params.Results.respiration;
do_spikes = params.Results.spikes;
do_photometry = params.Results.photometry;

%% globals
global MyFileName;
global subplotcol;
global SampleRate;
SampleRate = 500; % Samples/second
global startoffset;
startoffset = 1; % in seconds

%% core data extraction (and settings)
[MyData, MySettings, DataTags] = ReadSessionData(MyFilePath);
[FilePaths, MyFileName] = fileparts(MyFilePath);
disp(MyFileName);

% find timestamp of first trialON in the behavior file
TrialCol = find(cellfun(@isempty,regexp(DataTags,'TrialON'))==0);
TrialStart = MyData(find(diff([0; MyData(:,TrialCol)])>1,2,'first'),1); % timestamp of second trial start
    
%% Compare with Oeps aux signals if available
if ~isempty(WhereSpikeFile(MyFileName))
    [myephysdir] = WhereSpikeFile(MyFileName);
    [Aux,TTLs,AcqOffset] = GetOepsAuxChannels(myephysdir, TrialStart(end));
    
end

%% replot the behavior session - GUI style
if ReplotSession
    RecreateSession(MyData);
end

%% load previously saved session params
clear sessionstart sessionstop respthresh
if exist(fullfile(FilePaths,'processed',strrep(MyFileName,'.mat','_processed.mat')))
    disp('loading previously defined session flags');
    load(fullfile(FilePaths,'processed',strrep(MyFileName,'.mat','_processed.mat')),...
        'sessionstart','sessionstop','respthresh');

else
    % define session start and stop flags
    prompt = ['Enter start and stop timestamps: [',num2str(MyData(1,1)),' ',num2str(round(MyData(end,1))),']\n'];
    userans = input(prompt);
    sessionstart = userans(1);
    sessionstop = userans(2);
end

%% Process sniff data
if do_sniffs
    RespData = MyData(:,15);
    %[sniff_stamps] = GetRespirationTimeStamps(RespData, 0.2, 1);
end        
    
%% Parse into trials
[Traces, TrialInfo, TargetZones, TS] = ParseBehaviorTrials(MyData, MySettings, DataTags, sessionstart, sessionstop);

%% Align replay and close loop trials using openephys triggers
if any(diff(MySettings(:,32))== 2) && ~isempty(WhereSpikeFile(MyFileName))
    [myephysdir] = WhereSpikeFile(MyFileName);
    % get all TTLs for the open ephys session
    [TTLs] = GetOepsTTLs(myephysdir, TS);
    % Split the long replay trial in the behavior file
    % into individual trials using the Odor TTls in the Oeps file
    [Replay] = ParseReplayTrials(MyData, MySettings, DataTags, TrialInfo, TTLs);
    AlignBehaviorToOeps(MyData, myephysdir, TS, TrialInfo, Traces, Replay, []);
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
    
    if do_spikes
        %% get Spikes
        [myephysdir] = WhereSpikeFile(MyFileName);
        [SingleUnits, EphysTuningTrials] = Spikes2Trials(myephysdir, TS, TrialInfo, MyTuningTrials);
        
        if ~isempty(EphysTuningTrials)
            PlotTuning(SingleUnits, EphysTuningTrials, MyTuningTrials);
        end
        %PlotReplay(Traces, TrialInfo, TargetZones, Replay, SingleUnits);
        
        
%         savepath = fullfile(FilePaths,'processed',filesep,MyFileName);
%         save(strrep(savepath,'.mat','_processed.mat'),'Traces','TrialInfo',...
%             'TargetZones','spiketimes','sessionstart','sessionstop');
    end
    
    
    %     OdorTuningSummary;
    %     figureName = [MyFileName(1:end-4)];
    %     print(figureName,'-dpdf');
    %     close(gcf);
    
    %     for unit = 1:size(spiketimes,2)
    % %         figure;
    % %         PlotPSTH(unit,TrialInfo,spiketimes);
    % %         set(gcf,'Units','inches');
    % %         screenposition = get(gcf,'Position');
    % %         set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
    % %             'PaperSize',[screenposition(3:4)]);
    % %         figureName = [MyFileName(1:end-4),'_',num2str(unit),'_rasters'];
    % %         print(figureName,'-dpdf','-fillpage');
    % %         close(gcf);
    %
    % %         figure(2);
    % %         clf
    % %         PlotLocationOffsetPSTH(unit,Traces,TrialInfo,spiketimes);
    % %         pause(2);
    % %         %set(gcf,'Position',[274         365        1512         565]);
    % %         set(gcf,'Units','inches');
    % %         screenposition = get(gcf,'Position');
    % %         set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
    % %             'PaperSize',screenposition(3:4));
    % %         figureName = [MyFileName(1:end-4),'_',num2str(unit),'_offset'];
    % %         print(figureName,'-dpdf');
    % %         pause(5);
    %
    % %         subplotcol = rem(unit,5);
    % %         figure(1);
    % %         LeverSpikeHistograms(unit, Traces, TargetZones, TrialInfo, spiketimes);
    % %         pause(2);
    % %
    % %
    % %         if rem(unit,5) == 0 || unit == size(spiketimes,2)
    % %             figure(1);
    % %             set(gcf,'Units','inches');
    % %             screenposition = get(gcf,'Position');
    % %             set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
    % %                 'PaperSize',screenposition(3:4));
    % %             figureName = [MyFileName(1:end-4),'_',num2str(unit),'_tuning'];
    % %             print(figureName,'-dpdf');
    % %             pause(5);
    % %             clf
    % %
    % % %             if unit < size(spiketimes,2)
    % % %                 figure(1);
    % % %             end
    % %         end
    %
    %         subplotcol = rem(unit,6);
    %         if subplotcol == 0
    %             subplotcol = 6;
    %         end
    %         figure(1);
    %         PlotOdorArmTuning(unit,Traces,TrialInfo,spiketimes);
    %         pause(2);
    %
    %         if rem(unit,6) == 0 || unit == size(spiketimes,2)
    %             figure(1);
    %             set(gcf,'Units','inches');
    %             screenposition = get(gcf,'Position');
    %             set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
    %                 'PaperSize',screenposition(3:4));
    %             figureName = [MyFileName(1:end-4),'_',num2str(unit),'_armodortuning'];
    %             print(figureName,'-dpdf');
    %             pause(5);
    %             clf
    %         end
    %     end
%end
end
