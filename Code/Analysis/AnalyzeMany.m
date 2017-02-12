% test script to extract behavior data and replot session
function [Data] = AnalyzeMany(MouseName)

global timewindow;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

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
    
    %RecreateSession(Data.(['session',num2str(i)]).data);
    
%% Parse trials
    [Lever, TrialInfo, TargetZones] = SortSessionByTrials(Data.(['session',num2str(i)]).data);
    
%% Basic session statistics
    [Odors, ZonesToUse, LeverTruncated] = SortTrialsByType(Lever, TrialInfo, TargetZones);
    %[Histogram] = session_statistics(LeverTruncated, TrialInfo, ZonesToUse, Odors, 1);
    [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones);    

DoPlot = 1;
%% plot results
% Trajectories
figure('Name',[char(FileNames{i}),'ZoneAligned']);
for z = 1:numel(ZonesToUse)
    AverageTrajectories.(['Z',num2str(z)]).TargetZone = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).TargetZone,1);
    AverageTrajectories.(['Z',num2str(z)]).NonTarget = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).NonTarget,1);
    if DoPlot
        subplot(1,numel(ZonesToUse),z); hold on;
        shadedErrorBar(-timewindow:timewindow, AverageTrajectories.(['Z',num2str(z)]).TargetZone(1,:),AverageTrajectories.(['Z',num2str(z)]).TargetZone(4,:),'r');
        shadedErrorBar(-timewindow:timewindow, AverageTrajectories.(['Z',num2str(z)]).NonTarget(1,:), AverageTrajectories.(['Z',num2str(z)]).NonTarget(4,:), 'k');
    end
end

end
end