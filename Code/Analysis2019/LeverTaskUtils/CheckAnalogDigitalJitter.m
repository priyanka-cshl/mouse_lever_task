% Run the script from within the folder that contains the behavior files

DataRoot = pwd;
% get session files for analysis
[FileNames,FilePaths] = uigetfile('*_r*.mat','choose one or more session files','MultiSelect','on',DataRoot);

for i = 1:size(FileNames,2) % For each file
[~,T] = ParseBehaviorAndPhysiology(char(FileNames{i}));
X(i,1) = numel(find(T.TrialStart<0.99));
X(i,2) = numel(T.TrialStart);
end