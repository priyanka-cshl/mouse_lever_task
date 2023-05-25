
function [FileList] = OEPS_filematch()
global SampleRate;
SampleRate = 500; % Samples/second
global startoffset;
startoffset = 1; % in seconds
global errorflags; % [digital-analog sample drops, timestamp drops, RE voltage drift, motor slips]
errorflags = [0 0 0 0];

% get all files in the behavior directory
behavior_root = '/mnt/grid-hs/pgupta/Behavior/PCX3';

all_sessions = dir(fullfile(behavior_root,'PCX*_r*.mat'));
FileList = [];
for i = 1:size(all_sessions,1)
    MyFilePath = fullfile(behavior_root,all_sessions(i).name);
    disp(all_sessions(i).name);
    [MyData, MySettings, DataTags] = ReadSessionData(MyFilePath);
    % Parse into trials
    [Trials] = CorrectMatlabSampleDrops(MyData, MySettings, DataTags);
    [MyData, DataTags] = OdorLocationSanityCheck(MyData, DataTags);
    
    [myephysdir] = WhereSpikeFile(all_sessions(i).name,behavior_root);
%     if strcmp(all_sessions(i).name,'O1_20210917_r0.mat')
%         myephysdir = [];
%     end
%     if strcmp(all_sessions(i).name,'PCX3_20210504_r0.mat')
%         myephysdir = [];
%     end
    TTLs = [];
    if ~isempty(myephysdir)
        if size(myephysdir,1) == 1
            [TTLs] = GetOepsAuxChannels(myephysdir, Trials.TimeStamps, []); % send 'ADC', 1 to also get analog aux data
        else
            TTLs = [];
            while isempty(TTLs) && ~isempty(myephysdir)
                [TTLs] = GetOepsAuxChannels(myephysdir(1,:), Trials.TimeStamps, []);
                if isempty(TTLs)
                    myephysdir(1,:) = [];
                end
            end
        end
    end
    
    FileList{i,1} = all_sessions(i).name;
    FileList{i,3} = errorflags;
    if isempty(TTLs)
        FileList{i,2} = 0;
    else
        FileList{i,2} = 1;
    end
% writecell(FileList,fullfile(behavior_root,'FileMatchList.txt'),'Delimiter','tab');
end