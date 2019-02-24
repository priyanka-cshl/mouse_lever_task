%% function to parse behavioral data from the mouse lever task
% into trials, with relevant continuous (lever, motor, respiration, lickpiezo) 
% and event data (licks, target zone flags, odor ON-OFF, etc) for each trial

function [] = ParseBehavior(MouseName, ReplotSession)
if nargin < 2
    ReplotSession = 0;
end

% global timewindow;
global MyFileName;
global subplotcol
% timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms
global SampleRate;
SampleRate = 500; % Samples/second

[DataRoot] = WhichComputer(); % load rig specific paths etc

%% File selection
% Let the user select one or more behavioral files for analysis
if contains(MouseName,'.mat') % generally unused condition
    foo = strsplit(MouseName,'_');
    FileNames{1} = MouseName;
    MouseName = char(foo(1));
    FilePaths = fullfile(DataRoot,MouseName);
else
    DataRoot = fullfile(DataRoot,MouseName);
    % get session files for analysis
    [FileNames,FilePaths] = uigetfile('.mat','choose one or more session files','MultiSelect','on',DataRoot);
    if ~iscell(FileNames)
        temp = FileNames;
        clear FileNames
        FileNames{1} = temp;
        clear temp
    end
end

for i = 1:size(FileNames,2) % For each file
    
    %% core data extraction (and settings)
    MyFileName = FileNames{i};
    MyFilePath = fullfile(FilePaths,MyFileName);
    [MyData, MySettings, TargetZones, FakeTargetZones] = ExtractSessionDataFixedGain(MyFilePath);
    disp(MyFileName);
    
    %% manually assess the session to flag early and late session periods 
    % which contains 'un-motivated trials'
    if exist(fullfile(FilePaths,'processed',strrep(MyFileName,'.mat','_processed.mat')))
        load(fullfile(FilePaths,'processed',strrep(MyFileName,'.mat','_processed.mat')),...
            'sessionstart','sessionstop','respthresh');
    else
        sessionstart = 0;
        sessionstop = 0;
        if ReplotSession
            RecreateSession(MyData);
        end
%         sessionstart = str2double(input('Enter start timestamp:','s'));
%         sessionstop = str2double(input('Enter stop timestamp:','s'));
        sessionstart = 0;
        sessionstop = -1;
        
        if sessionstart<0
            sessionstart = 0;
        end
        if sessionstop<0
            sessionstop = MyData(end,1);
        end
    end
    
    %% Parse trials
    [Traces, TrialInfo, TargetZones] = ParseTrials(MyData, MySettings, TargetZones, sessionstart, sessionstop);
    
    %% get Spikes
    [myephysdir] = WhereSpikeFile(MyFileName);
    [spiketimes] = Spikes2Trials(myephysdir);
    
    for unit = 1:size(spiketimes,2)
%         figure;
%         PlotPSTH(unit,TrialInfo,spiketimes);
%         set(gcf,'Units','inches');
%         screenposition = get(gcf,'Position');
%         set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
%             'PaperSize',[screenposition(3:4)]);
%         figureName = [MyFileName(1:end-4),'_',num2str(unit),'_rasters'];
%         print(figureName,'-dpdf','-fillpage');
%         close(gcf);
        
%         figure(2);
%         clf
%         PlotLocationOffsetPSTH(unit,Traces,TrialInfo,spiketimes);
%         pause(2);
%         %set(gcf,'Position',[274         365        1512         565]);
%         set(gcf,'Units','inches');
%         screenposition = get(gcf,'Position');
%         set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
%             'PaperSize',screenposition(3:4));
%         figureName = [MyFileName(1:end-4),'_',num2str(unit),'_offset'];
%         print(figureName,'-dpdf');
%         pause(5);
        
%         subplotcol = rem(unit,5);
%         figure(1);
%         LeverSpikeHistograms(unit, Traces, TargetZones, TrialInfo, spiketimes);
%         pause(2);
%         
%         
%         if rem(unit,5) == 0 || unit == size(spiketimes,2)
%             figure(1);
%             set(gcf,'Units','inches');
%             screenposition = get(gcf,'Position');
%             set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
%                 'PaperSize',screenposition(3:4));
%             figureName = [MyFileName(1:end-4),'_',num2str(unit),'_tuning'];
%             print(figureName,'-dpdf');
%             pause(5);
%             clf
%             
% %             if unit < size(spiketimes,2)
% %                 figure(1);
% %             end
%         end

        subplotcol = rem(unit,6);
        if subplotcol == 0
            subplotcol = 6;
        end
        figure(1);
        PlotOdorArmTuning(unit,Traces,TrialInfo,spiketimes);
        pause(2);
        
        if rem(unit,6) == 0 || unit == size(spiketimes,2)
            figure(1);
            set(gcf,'Units','inches');
            screenposition = get(gcf,'Position');
            set(gcf,'PaperPosition',[0 0 screenposition(3:4)],...
                'PaperSize',screenposition(3:4));
            figureName = [MyFileName(1:end-4),'_',num2str(unit),'_armodortuning'];
            print(figureName,'-dpdf');
            pause(5);
            clf
        end
    end
    end
end
