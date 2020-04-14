% test script to extract behavior data and replot session
function [] = AnalyzeMany(MouseName, ReplotSession)
if nargin < 2
    ReplotSession = 0;
end

global timewindow;
global MyFileName;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

[DataRoot] = WhichComputer();

if ~isempty(strfind(MouseName,'.mat'))
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

for i = 1:size(FileNames,2)
    
    %% core data extraction (and settings)
    Data.(['session',num2str(i)]).path = fullfile(FilePaths,FileNames{i});
    [Data.(['session',num2str(i)]).data, Data.(['session',num2str(i)]).settings, TargetZones, FakeTargetZones] = ...
        ExtractSessionDataFixedGain(fullfile(FilePaths,FileNames{i}));
    MyFileName = FileNames{i};
    disp(MyFileName);
    
    clear respthresh
    if exist(fullfile(FilePaths,'processed',strrep(MyFileName,'.mat','_processed.mat')))
        load(fullfile(FilePaths,'processed',strrep(MyFileName,'.mat','_processed.mat')),...
            'sessionstart','sessionstop','respthresh');
    else
        sessionstart = 0;
        sessionstop = 0;
        if ReplotSession
            RecreateSession(Data.(['session',num2str(i)]).data);
        end
%         sessionstart = str2double(input('Enter start timestamp:','s'));
%         sessionstop = str2double(input('Enter stop timestamp:','s'));
        sessionstart = 0;
        sessionstop = Inf;
    end
    
    if sessionstop
        close(gcf);
        if exist('respthresh','var') && respthresh ~= 0
            RespData = Data.(['session',num2str(i)]).data(:,15);
            TimeStamps = Data.(['session',num2str(i)]).data(:,1);
            threshold = respthresh;
            [sniff_stamps] = GetRespirationTimeStamps(RespData, respthresh);
        else
            respthresh = 0;
            sniff_stamps = [];
%             newthreshold = 0.2;
%             
%             %% Process Respiration Data
%             while newthreshold
%                 if size(Data.(['session',num2str(i)]).data,2)>=15 & median(Data.(['session',num2str(i)]).data(:,15)>0)
%                     RespData = Data.(['session',num2str(i)]).data(:,15);
%                     TimeStamps = Data.(['session',num2str(i)]).data(:,1);
%                     threshold = 0.2;
%                     [sniff_stamps] = GetRespirationTimeStamps(RespData, newthreshold);
%                 end
%                 respthresh = newthreshold;
%                 disp(['current threshold = ',num2str(respthresh)]);
%                 newthreshold = str2double(input('Enter new threshold: [0 if current thresh is ok] ','s'));
%             end
        end
%         close(gcf);
        
        %% Parse trials
        [Traces, TrialInfo, TargetZones] = ChunkToTrials(Data.(['session',num2str(i)]).data, TargetZones, sessionstart, sessionstop, sniff_stamps);
        [Odors, ZonesToUse, Traces] = TruncateTrials(Traces, TrialInfo, TargetZones);
        
        %% Correct for incorrect Target Zone assignments
        %[TrialInfo] = FixTargetZoneAssignments(Data.(['session',num2str(i)]).data,TrialInfo,TargetZones,Data.(['session',num2str(i)]).settings);
        
        %% Get TFs
        if size(Data.(['session',num2str(i)]).settings,2)>=35
            [AllTFs] = GetAllTransferFunctions(Data.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:),'fixedgain');
        else
            if abs(mode(MotorTruncated(:,1)))<70
                [AllTFs] = GetAllTransferFunctions(Data.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:),'fixedspeed');
            else
                [AllTFs] = GetAllTransferFunctions(Data.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:));
            end
        end
        
        %% Trajectory Analysis
        [Trajectories, TrajectoryStats, ZoneStays, Exhalations, Inhalations] = GroupTrajectories(Traces, TrialInfo, TargetZones, Data.(['session',num2str(i)]).settings);
        
        %% save processed files
        savepath = fullfile(FilePaths,'processed',filesep,MyFileName);
        save(strrep(savepath,'.mat','_processed.mat'),'Trajectories','TrajectoryStats','ZoneStays','sessionstart','sessionstop','respthresh', 'Exhalations', 'Inhalations');
        
        %     %% Basic session statistics
        %     [NumTrials] = SessionStats(TrialInfo,Trajectories,ZonesToUse,TargetZones,1);
        %
        %     % if number of Zones>6 split the data set into two
        %
        %     if numel(ZonesToUse)>6
        %        HistogramOfOccupancy(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, AllTFs, Trajectories, 1);
        %        [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, Data.(['session',num2str(i)]).settings, 1);
        %
        %     elseif numel(ZonesToUse)>3
        %         LeverTruncated_all = LeverTruncated;
        %         TrialInfo_all = TrialInfo;
        %         TargetZones_all = TargetZones;
        %         ZonesToUse_all = ZonesToUse;
        %
        %         n = numel(ZonesToUse)/3;
        %         for m = 1:n
        %             f = find(mod(TrialInfo_all.TargetZoneType,n)==m-1);
        %             LeverTruncated = LeverTruncated_all(f,:);
        %             TrialInfo.TargetZoneType = TrialInfo_all.TargetZoneType(f,:);
        %             TrialInfo.Success = TrialInfo_all.Success(f,:);
        %             TargetZones = TargetZones_all(n+1-m:n:end,:);
        %             ZonesToUse = ZonesToUse_all(n+1-m:n:end,:);
        %             [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 1);
        %             %[StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, 1);
        %             [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 2, 1);
        %         end
        %
        %     else
        %         [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, Data.(['session',num2str(i)]).settings, 1);
        %         %[StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, Data.(['session',num2str(i)]).settings, 1);
        %         %[Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 2, 1);
        %     end
    end
end
end