% test script to extract behavior data and replot session
% for animals trained on the fixed gain version of the task (post 08.2018)

function [MyData, MyParams, MyTrials] = ExtractTuningSession(FileName, PIDflag)
global SampleRate;

if nargin<2
    PIDflag = 0;
end

%% load the file
Temp = load(FileName,'session_data');
MyTraces = Temp.session_data.trace;
MyParams = Temp.session_data.params;
TrialSequence = Temp.session_data.TrialSequence;
[nrows, ~] = size(MyTraces);

if PIDflag
    % [PID* RotaryEncoder TrialON InTargetZone InRewardZone Rewards
    % Licks]
    % * PID was acquired on the lick piezo channel
    MyData = MyTraces(:,[6 3 7:11]);
else
    % [Lever RotaryEncoder TrialON InTargetZone InRewardZone Rewards
    % Licks HomeSensor Camera1 Camera2]
    MyData = MyTraces(:,[1 3 7:11]);
    
    % add 3 cols in the beginning [timestamps TZoneHighLim TZoneLowLim ...
    % add 2 cols in the end [FZoneHighLim FZoneLowLim]
    MyData = horzcat(Temp.session_data.timestamps, zeros(nrows,2), MyData, zeros(nrows,2));
    
    % append motor location
    MyData(:,13) = MyTraces(:,4);
    
    if find(ismember(Temp.session_data.trace_legend,'homesensor'))
        whichcol = find(ismember(Temp.session_data.trace_legend,'homesensor'));
        MyData(:,14) = MyTraces(:,whichcol);
    end
        
    if ~isempty(find(ismember(Temp.session_data.trace_legend,'thermistor')))
        whichcol = find(ismember(Temp.session_data.trace_legend,'thermistor'));
    else
        whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
    end
    MyData(:,15) = MyTraces(:,whichcol);
    
    if find(ismember(Temp.session_data.trace_legend,'camerasync'))
        whichcol = find(ismember(Temp.session_data.trace_legend,'camerasync'));
        MyData(:,16) = MyTraces(:,whichcol);
    end
    
    if size(MyTraces,2)>whichcol % if there was a second camera
        whichcol = whichcol + 1;
        MyData(:,17) = MyTraces(:,whichcol);
    end
    
end

clear Temp

%% Get Trial ON-OFF timestamps
TrialColumn = MyData(:,6);
TrialColumn(TrialColumn~=0) = 1; % make logical
TrialOn = find(diff(TrialColumn)>0);
TrialOff =  find(diff(TrialColumn)<0)+1;

% account for cases where acquisition started/ended in between a trial
while TrialOn(1)>TrialOff(1)
    TrialOff(1,:) = [];
end
while TrialOn(end)>TrialOff(end)
    TrialOn(end,:) = [];
end

MyTrials = [NaN*ones(length(TrialOn),2) TrialOn TrialOff MyData(TrialOn,1) MyData(TrialOff,1)];
MyTrials(:,7) = MyTrials(:,6) - MyTrials(:,5); 

%% Odor ON-OFF timestamps
OdorColumn = MyData(:,8);
OdorOn = find(diff(OdorColumn)>0);
OdorOff =  find(diff(OdorColumn)<0)+1;

MotorColumn = MyData(:,13);

% Fill up the Trials Table with odor on-off timestamps
for i = 1:size(MyTrials,1)
    if ~isempty(intersect(find(OdorOn>MyTrials(i,3)),find(OdorOn<MyTrials(i,4))))
        MyTrials(i,8) = OdorOn(intersect(find(OdorOn>MyTrials(i,3)),find(OdorOn<MyTrials(i,4))));
        MyTrials(i,10) = MyData(MyTrials(i,8),1); % timestamp
    end
    if ~isempty(intersect(find(OdorOff>MyTrials(i,3)),find(OdorOff<MyTrials(i,4))))
        MyTrials(i,9) = OdorOff(intersect(find(OdorOff>MyTrials(i,3)),find(OdorOff<MyTrials(i,4))));
        MyTrials(i,11) = MyData(MyTrials(i,9),1); % timestamp
    end
    % get the motor position
    MyTrials(i,12) = mode(MotorColumn(MyTrials(i,3):MyTrials(i,4),1));
end

% Looks like if there were passive replays - spurious trials get inserted
% the seem to have the wrong motor location
TrialSequence(:,1:2) = circshift(TrialSequence(:,1:2),1); % bug in all sessions
TrialSequence(1,2) = NaN;

foo = find(TrialSequence(:,1)==999);
if any(foo)
    for i = 1:numel(foo)
        Temp = MyTrials(:,12);
        idx = foo(i) + [-1 2 3]';
        delta = TrialSequence(idx,1)-Temp(idx,1);
        if any(abs(delta)>5)
            % try deleting the entry just after the replay
            Temp(foo(i)+1,:) = [];
            delta = TrialSequence(idx,1)-Temp(idx,1);
            if ~any(abs(delta)>5)
                MyTrials(foo(i)+1,:) = [];
            end
        end
                
    end
    MyTrials(:,1:2) = TrialSequence;
else
    MyTrials(:,1:2) = TrialSequence;
    if any(abs(TrialSequence(2:end,1) - MyTrials(2:end,1))>5)
        disp('location mismatches in tuning file')
    end
end

end