% test script to extract behavior data and replot session
function [DataOut] = AnalyzePIDTraces(MouseName, ReplotSession)
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
        ExtractSessionData(fullfile(FilePaths,FileNames{i}),1);
    MyFileName = FileNames{i};
    
    if ReplotSession
        RecreateSession(Data.(['session',num2str(i)]).data);
    end
    
    %% Parse trials
    [PID, Motor, TrialInfo, TargetZones] = ChunkUpTrials(Data.(['session',num2str(i)]).data, TargetZones, FakeTargetZones);
    %[Odors, ZonesToUse, PIDTruncated, MotorTruncated] = TruncateTrials(PID, Motor, TrialInfo, TargetZones);
    
    [Data.(['session',num2str(i)]).data, Data.(['session',num2str(i)]).settings, TargetZones, FakeTargetZones] = ...
        ExtractSessionData(fullfile(FilePaths,FileNames{i}));
    [Lever, Motor, TrialInfo, TargetZones] = ChunkUpTrials(Data.(['session',num2str(i)]).data, TargetZones, FakeTargetZones);
    
    [Odors, ZonesToUse, LeverTruncated, MotorTruncated, PIDTruncated, TrialInfo] = TruncateAlignTrials(Lever, Motor, TrialInfo, TargetZones, PID);
    
    %% put in data out
    DataOut(i).filename = MyFileName;
    DataOut(i).Lever = LeverTruncated;
    DataOut(i).Motor = MotorTruncated;
    DataOut(i).PID = PIDTruncated;
    DataOut(i).TargetZones = TargetZones;
    DataOut(i).TrialInfo = TrialInfo;
    DataOut(i).Odors = Odors;
end
end