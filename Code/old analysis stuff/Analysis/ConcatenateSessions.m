function [] = ConcatenateSessions(MouseName)

global timewindow;
timewindow = 100; % sampling rate of 500 Hz, 50 points = 100ms

[DataRoot] = WhichComputer();

DataRoot = fullfile(DataRoot,MouseName);
% get session files for analysis
[FileNames,FilePaths] = uigetfile('.mat','choose one or more session files','MultiSelect','on',DataRoot);
if ~iscell(FileNames)
    temp = FileNames;
    clear FileNames
    FileNames{1} = temp;
    clear temp
end

Timestamp_offset = 0;
session_data.timestamps = [];
session_data.trace = [];
session_data.params = [];

for i = 1:size(FileNames,2) 
    % load the data
    Temp = load(fullfile(FilePaths,FileNames{i}),'session_data');
    % offset Timestamps and concatenate
    session_data.timestamps = [session_data.timestamps; ...
        (Temp.session_data.timestamps + Timestamp_offset)];
    session_data.trace = [session_data.trace; Temp.session_data.trace];
    if i > 1
        % delete first two param entries
        myparams = Temp.session_data.params;
        myparams(1:find(myparams(:,1)==0,1,'last'),:) = [];
    else
        myparams = Temp.session_data.params;
    end
    
    myparams(myparams(:,1)>0,1) = myparams(myparams(:,1)>0,1)  + Timestamp_offset;
    myparams(myparams(:,1)<0,1) = myparams(myparams(:,1)<0,1)  - Timestamp_offset;
    session_data.params = [session_data.params; myparams];
    
    Timestamp_offset = session_data.timestamps(end);
    
end

% keep params of the last session for next session upload
% session_data.legends_main = Temp.session_data.legends_main;
% session_data.params_main = Temp.session_data.params_main;
% session_data.legends_trial = Temp.session_data.legends_trial;
session_data.legends = Temp.session_data.legends;
session_data.trace_legend = Temp.session_data.trace_legend;
session_data.TF = Temp.session_data.TF;
session_data.ForNextSession = Temp.session_data.ForNextSession;
session_data.ForNextSession_Legends = Temp.session_data.ForNextSession_Legends;
session_data.concatenated = FileNames; %#ok<STRNU>

% save new concatenated files
Newfilename = [FileNames{i}(1:regexp(FileNames{i},'_r[0-9].mat')),'r',num2str(i+1),'_concatenated.mat'];
filename = fullfile(DataRoot,Newfilename);
save(filename,'session_data*');
disp(['saved ',filename]);

end