% test script to extract behavior data and replot session
function [Data] = AnalyzeMany(MouseName)

DataRoot = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
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
    
%% Parse trials
    [Lever, TrialInfo, TargetZones] = SortSessionByTrials(Data.(['session',num2str(i)]).data);
    
%% Basic session statistics
    [Odors, ZonesToUse, LeverTruncated] = SortTrialsByType(Lever, TrialInfo, TargetZones);
    %[Histogram] = session_statistics(LeverTruncated, TrialInfo, ZonesToUse, Odors, 1);
    [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, 1);
    
end
end