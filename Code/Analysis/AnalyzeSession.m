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
    Data.(['session',num2str(i)]).path = fullfile(FilePaths,FileNames{i});
    
    %Output = ParseSession(MyFileName, ReplotSession, Plotting)
    Output = ParseSession(Data.(['session',num2str(i)]).path, ReplotSession, Plotting);
    
    Data.(['session',num2str(i)]).TargetZones = Output.TargetZones;
    Data.(['session',num2str(i)]).ZonesToUse = Output.ZonesToUse;
    Data.(['session',num2str(i)]).TrialInfo = Output.TrialInfo;
    Data.(['session',num2str(i)]).Trajectories = Output.Trajectories;
    Data.(['session',num2str(i)]).StayTimes = Output.StayTimes;
    Data.(['session',num2str(i)]).TrialStats = Output.TrialStats;
 
end
end