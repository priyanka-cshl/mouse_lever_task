% test script to extract behavior data and replot session
function [] = AnalyzeSession(MouseName, ReplotSession)
if nargin < 2
    ReplotSession = 0;
end

global timewindow;
global MyFileName;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

% read computer name
!hostname > hostname.txt
computername = char(textread('hostname.txt','%s'));

switch computername
    case 'priyanka-gupta.cshl.edu'
        DataRoot = '/Volumes/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
    case 'priyanka-gupta.home'
        if exist('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior','dir')
            DataRoot = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % local copy
        else
            DataRoot = '/Volumes/Albeanu-Norepl/pgupta/Behavior'; 
        end
    case 'Priyanka-PC'
        DataRoot = 'C:\Data\Behavior'; % location on rig computer
    otherwise
        DataRoot = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
end

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
        ExtractSessionData(fullfile(FilePaths,FileNames{i}));
    MyFileName = FileNames{i};
    
    if ReplotSession
        RecreateSession(Data.(['session',num2str(i)]).data);
    end
    
    %% Parse trials
    [Lever, Motor, TrialInfo, TargetZones] = ChunkUpTrials(Data.(['session',num2str(i)]).data, TargetZones, FakeTargetZones);
    [Odors, ZonesToUse, LeverTruncated, MotorTruncated] = TruncateTrials(Lever, Motor, TrialInfo, TargetZones);
    
    %% Correct for incorrect Target Zone assignments
    [TrialInfo] = FixTargetZoneAssignments(Data.(['session',num2str(i)]).data,TrialInfo,TargetZones,Data.(['session',num2str(i)]).settings);
    
    %% Get TFs
    [AllTFs] = GetAllTransferFunctions(Data.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:));
    
    %% Trajectory Analysis
    if i == 1
        if any(find(~TrialInfo.TransferFunctionLeft))
            [TrajectoriesLeft] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1);
            [TrajectoriesRight] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,2);
            [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones);
        else
            [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones);
        end
    else
        [Trajectories] = OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1);
    end
    
    %% Basic session statistics
    [NumTrials] = SessionStats(TrialInfo,Trajectories,ZonesToUse,TargetZones,1);    
    
    %% Histograms
    HistogramOfOccupancy(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, AllTFs, Trajectories, 1);
    [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, Data.(['session',num2str(i)]).settings, 1);
        

end
end