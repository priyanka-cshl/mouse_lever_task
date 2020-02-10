clear all
VideoFolder = ...
    '/Volumes/Seagate Backup Plus Drive/BehaviorVideos/N8/20190205';

% get frame counts from Video Files
cd (VideoFolder);
GetVideoFrameCounts;
clearvars -except NumFrames

BehaviorFile = ...
    '/Volumes/Seagate Backup Plus Drive/BehaviorData/N8/N8_20190205_r0.mat';
% get behavior traces
[MyData, ~, ~, ~] = ExtractTracesAndEvents(BehaviorFile);
[Traces, CamA, CamB, TrialInfo] = ParseTrialsVideoSync(MyData);
clearvars -except NumFrames Traces CamA CamB TrialInfo BehaviorFile

[~,foo] = fileparts(BehaviorFile);
savefilename = [foo(1:strfind(foo,'_r')-1),'.mat'];
SavePath = '/Users/Priyanka/Desktop/VideoAlignedBehaviorData/N8';
save(fullfile(SavePath,savefilename),'Traces',...
    'CamA', 'CamB', 'TrialInfo', 'NumFrames');
