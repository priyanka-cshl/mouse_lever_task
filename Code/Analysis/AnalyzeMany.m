% test script to extract behavior data and replot session
function [] = AnalyzeMany(MouseName)

global timewindow;
global MyFileName;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

% read computer name
!hostname > hostname.txt
computername = char(textread('hostname.txt','%s'));

switch computername
    case 'priyanka-gupta.cshl.edu'
        DataRoot = '/Volumes/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
    case 'Priyanka-PC'
        DataRoot = 'C:\Data\Behavior'; % location on rig computer
    otherwise
        DataRoot = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
end
DataRoot = fullfile(DataRoot,MouseName);

% get session files for analysis
[FileNames,FilePaths] = uigetfile('.mat','choose one or more session files','MultiSelect','on',DataRoot);
if ~iscell(FileNames)
    temp = FileNames;
    clear FileNames
    FileNames{1} = temp;
    clear temp
end

for i = 1:size(FileNames,2) 
    
    %% core data extraction (and settings)
    Data.(['session',num2str(i)]).path = fullfile(FilePaths,FileNames{i});
    [Data.(['session',num2str(i)]).data, Data.(['session',num2str(i)]).settings] = ...
        ExtractSessionData(fullfile(FilePaths,FileNames{i}));
    MyFileName = FileNames{i};
    RecreateSession(Data.(['session',num2str(i)]).data);
    
    %% Parse trials
    [Lever, TrialInfo, TargetZones] = SortSessionByTrials(Data.(['session',num2str(i)]).data);
    
    %% Basic session statistics
    [Odors, ZonesToUse, LeverTruncated] = SortTrialsByType(Lever, TrialInfo, TargetZones);
%     [NumTrials] = SessionSummary(TrialInfo,ZonesToUse,TargetZones,1);    
    
    %% Trajectory Analysis
%     ParameterizeTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones);
    
    
    % if number of Zones>6 split the data set into two
    if numel(ZonesToUse)>3
        LeverTruncated_all = LeverTruncated;
        TrialInfo_all = TrialInfo;
        TargetZones_all = TargetZones;
        ZonesToUse_all = ZonesToUse;
        
        n = numel(ZonesToUse)/3;
        for m = 1:n
            f = find(mod(TrialInfo_all.TargetZoneType,n)==m-1);
            LeverTruncated = LeverTruncated_all(f,:);
            TrialInfo.TargetZoneType = TrialInfo_all.TargetZoneType(f,:);
            TrialInfo.Success = TrialInfo_all.Success(f,:);
            TargetZones = TargetZones_all(n+1-m:n:end,:);
            ZonesToUse = ZonesToUse_all(n+1-m:n:end,:);
            [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 1);
            %[StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, 1);
            [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 2, 1);
        end
    else
%         [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 1);
%         [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, 1);
%         [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 2, 1);
    end

end
end