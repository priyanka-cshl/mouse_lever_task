% test script to extract behavior data and replot session
function [] = AnalyzeMany(MouseName, ReplotSession)
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
    case {'priyanka-gupta.home', 'priyanka-gupta.local'}
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
    if abs(mode(MotorTruncated(:,1)))<70
        [AllTFs] = GetAllTransferFunctions(Data.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:),'fixedspeed');
    else
        [AllTFs] = GetAllTransferFunctions(Data.(['session',num2str(i)]).settings, TargetZones(ZonesToUse,:));
    end
    
    %% Trajectory Analysis
     [Trajectories] = SortTrajectories2018(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, Data.(['session',num2str(i)]).settings, 1);
   %  [Trajectories] = SingleTrialTrajectories2018(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, 1);
%     [Trajectories] = SingleTrialTrajectoriesLocationOffset2018(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, Data.(['session',num2str(i)]).settings, 1);
   %  SortMotorTrajectories2018(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, Data.(['session',num2str(i)]).settings, 1);

     %     if i == 1
%         [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, 1);
%     else
%         [Trajectories] = OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1);
%     end
    %% Basic session statistics
    [NumTrials] = SessionStats(TrialInfo,Trajectories,ZonesToUse,TargetZones,1);    
    
    % if number of Zones>6 split the data set into two
    
    if numel(ZonesToUse)>6
       HistogramOfOccupancy(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, AllTFs, Trajectories, 1);
       [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, Data.(['session',num2str(i)]).settings, 1);
        
    elseif numel(ZonesToUse)>3
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
        [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, Data.(['session',num2str(i)]).settings, 1);
        %[StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, Data.(['session',num2str(i)]).settings, 1);
        %[Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 2, 1);
    end

end
end