% test script to extract behavior data and replot session
function [Data] = AnalyzeSession(MouseName, ReplotSession)
if nargin < 2
    ReplotSession = 0;
end

Plotting = 1; %1 = plot results

global timewindow;
global MyFileName;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

% read computer name
!hostname > hostname.txt
computername = char(textread('hostname.txt','%s'));

switch computername
    case 'priyanka-gupta.cshl.edu'
        DataRoot = '/Volumes/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
    case {'priyanka-gupta.home','priyanka-gupta.local'}
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
    i
    %% core data extraction (and settings)
    Data.(['session',num2str(i)]).path = fullfile(FilePaths,FileNames{i});
    [MyData.(['session',num2str(i)]).data, MyData.(['session',num2str(i)]).settings, TargetZones, FakeTargetZones] = ...
        ExtractSessionData(fullfile(FilePaths,FileNames{i}));
    MyFileName = FileNames{i};
    
    %% Parse trials
    [Lever, Motor, TrialInfo, TargetZones] = ChunkUpTrials(MyData.(['session',num2str(i)]).data, TargetZones, FakeTargetZones);
    [Odors, ZonesToUse, LeverTruncated, MotorTruncated] = TruncateTrials(Lever, Motor, TrialInfo, TargetZones);
    
    %% Correct for incorrect Target Zone assignments
    [TrialInfo,MyData.(['session',num2str(i)]).data] = FixTargetZoneAssignments(MyData.(['session',num2str(i)]).data,TrialInfo,TargetZones,MyData.(['session',num2str(i)]).settings);
    if ReplotSession
        RecreateSession(MyData.(['session',num2str(i)]).data);
    end
    
    %% Get TFs
    [AllTFs] = GetAllTransferFunctions(MyData.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:));
    
    %% Trajectory Analysis
    if i == 1
        if any(find(~TrialInfo.TransferFunctionLeft))
            SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1, 1);
            OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1, 2);
            [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, 0, 0);
        else
            [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, 1, 1);
        end
    else
        [Trajectories] = OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1);
    end
    %[Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, Plotting);
    
    %% Basic session statistics
    [NumTrials] = SessionStats(TrialInfo,Trajectories,ZonesToUse,TargetZones,Plotting);    
    
    %% Histograms
    HistogramOfOccupancy(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, AllTFs, Trajectories, Plotting);
    [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, MyData.(['session',num2str(i)]).settings, Plotting);
    
    Data.(['session',num2str(i)]).TargetZones = TargetZones;
    Data.(['session',num2str(i)]).ZonesToUse = ZonesToUse;
    Data.(['session',num2str(i)]).TrialInfo = TrialInfo;
    Data.(['session',num2str(i)]).Trajectories = Trajectories;
    Data.(['session',num2str(i)]).StayTimes = StayTimes;
    Data.(['session',num2str(i)]).TrialStats = TrialStats;
 
end
end