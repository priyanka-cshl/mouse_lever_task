% test script to extract behavior data and replot session
function [DataOut] = AnalyzeOpenLoop(MouseName, whichcase, deletefirsttrial)
if nargin < 2
    whichcase = '';
end
if nargin < 3
    deletefirsttrial = 0;
end

global DataRoot;
global timewindow;
global MyFileName;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

% read computer name
!hostname > hostname.txt
computername = char(textread('hostname.txt','%s'));

if ~exist(DataRoot,'dir')
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
    ThisSessionPath = fullfile(FilePaths,FileNames{i});
    
    switch whichcase
        case 'PID'
            [ThisSessionData, ThisSessionTrialSequence, ThisSessionParams] = ...
                ExtractOpenLoopData(fullfile(FilePaths,FileNames{i}),1);
        otherwise
            [ThisSessionData,  ThisSessionTrialSequence, ThisSessionParams] = ...
                ExtractOpenLoopData(fullfile(FilePaths,FileNames{i}),0);
    end
    
    MyFileName = FileNames{i};
    
    %% Parse trials
    [Traces, Motor, TrialInfo, Respiration] = ChunkUpOpenLoopTrials(ThisSessionData, ThisSessionTrialSequence, deletefirsttrial);
    
    [Odors, Locations, LeverTruncated, MotorTruncated] = TruncateAlignOpenLoopTrials(Traces, Motor, TrialInfo);
    
    %% put in data out
    DataOut(i).filename = MyFileName;
    switch whichcase
        case 'PID'
            DataOut(i).PID = LeverTruncated;
        otherwise
            DataOut(i).Lever = LeverTruncated;
    end
    DataOut(i).Motor = MotorTruncated;
    DataOut(i).Locations = Locations;
    DataOut(i).TrialInfo = TrialInfo;
    DataOut(i).Odors = Odors;
    
    %% keep track of sessionwise data
    %     Data.(['session',num2str(i)]).path = ThisSessionPath;
    %     Data.(['session',num2str(i)]).data = ThisSessionData;
    %     Data.(['session',num2str(i)]).TrialSequence = ThisSessionTrialSequence;
    %     Data.(['session',num2str(i)]).settings = ThisSessionParams;
end
end