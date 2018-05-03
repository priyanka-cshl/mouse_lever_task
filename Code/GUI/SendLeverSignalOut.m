% set up analog out
s = daq.createSession('ni');
addAnalogOutputChannel(s,'Dev1',0,'Voltage');
s.Rate = 500;

% get lever session to send out
% [FileNames,FilePaths] = uigetfile('.mat','choose one or more session files','MultiSelect','on','C:\Data\Behavior\PG03');
% if ~iscell(FileNames)
%     temp = FileNames;
%     clear FileNames
%     FileNames{1} = temp;
%     clear temp
% end
myfile = 'C:\Data\Behavior\PG03\PG03_20180306_r1.mat';
MyTraces = ExtractSessionData(myfile);
start_idx = 500*0.8; stop_idx = 500*19.0; 
MyLever = repmat(MyTraces(start_idx:stop_idx,4),5,1);
scale_factor = [2.5 0.2];
MyLever = (MyLever - scale_factor(2))/scale_factor(1);
plot(MyLever);
queueOutputData(s,MyLever);

pause(1);

s.startForeground;