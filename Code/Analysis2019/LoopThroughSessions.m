
%% Script for running behavior related analysis on multiple sessions in a loop

MouseName = 'J4';
%Options = ['plotsession',0,'chunksession',0,'respiration',0,...
%           'tuning',0,'replay',0,'spikes',0,'photometry',0]; 

%% File selection
[DataRoot] = WhichComputer(); % load rig specific paths etc
% Let the user select one or more behavioral files for analysis
if contains(MouseName,'.mat') % generally unused condition
    foo = strsplit(MouseName,'_');
    FileNames{1} = MouseName;
    MouseName = char(foo(1));
    FilePaths = fullfile(DataRoot,MouseName);
else
    DataRoot = fullfile(DataRoot,MouseName);
    % get session files for analysis
    [FileNames,FilePaths] = uigetfile('*_r*.mat','choose one or more session files','MultiSelect','on',DataRoot);
    if ~iscell(FileNames)
        temp = FileNames;
        clear FileNames
        FileNames{1} = temp;
        clear temp
    end
end

for i = 1:size(FileNames,2) % For each file
    
    MyFileName = FileNames{i};
    MyFilePath = fullfile(FilePaths,MyFileName);

    ParseBehaviorAndPhysiology(MyFilePath);       

end
