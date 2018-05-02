% s = daq.createSession('ni'); % create a NI session
% addAnalogOutputChannel(s,'Dev1',0,'Voltage'); % add an analog output channel

% get session files for uploading
[FileNames,FilePaths] = uigetfile('.mat','choose one or more session files','MultiSelect','off');
if ~iscell(FileNames)
    temp = FileNames;
    clear FileNames
    FileNames{1} = temp;
    clear temp
end
myfile = fullfile(FilePaths,FileNames{1});
[MyData] = ExtractSessionData(myfile);

% column 4 is lever data



