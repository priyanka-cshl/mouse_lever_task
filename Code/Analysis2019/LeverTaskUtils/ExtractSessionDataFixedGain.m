% test script to extract behavior data and replot session
% for animals trained on the fixed gain version of the task (post 08.2018)

function [MyData, MyParams, TargetZones, FakeTargetZones] = ExtractSessionDataFixedGain(FileName, PIDflag)
if nargin<2
    PIDflag = 0;
end

%% load the file
Temp = load(FileName,'session_data');
MyTraces = Temp.session_data.trace;
MyParams = Temp.session_data.params;
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
    
    if find(ismember(Temp.session_data.trace_legend,'respiration'))
        whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
        MyData(:,15) = MyTraces(:,whichcol);
    end
    
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

%% clean up params table
% HACK - in some versions of the code, params were written to
% disc with -ve timestamp before an actual update happened
% only start with entries that have non-zero timestamps
MyParams(1: find(MyParams(:,1)==0,1,'last')-1,:) = [];
% if timestamps are negative - ignore those
MyParams(find(MyParams(:,1)<0),:) = [];

% HACK: for first day of block shifts - fix target zone definitions
f = find(MyParams(:,23)~=121);
if ~isempty(f)
    U = unique(MyParams(:,18:20),'rows');
    for i = 1:size(U,1)
        if rem(U(i,2),0.25)
            x = find(MyParams(:,19) == U(i,2));
            y = find(abs(MyParams(:,19) - U(i,2) + 0.6)<=0.1); 
            for j = 1:numel(x)
                MyParams(x(j),18:20) = MyParams(y(1),18:20); 
            end
        end
    end
end

% for each trial
for thisTrial = 1:size(MyParams,1)
    
    %% Get target zone values
    if thisTrial < size(MyParams,1)
        f = find((MyData(:,1)>=MyParams(thisTrial,1)) &...
            (MyData(:,1)<MyParams(thisTrial+1,1)));
    else
        f = find(MyData(:,1)>=MyParams(end,1));
    end
    MyData(f,2) = MyParams(thisTrial,18);
    MyData(f,3) = MyParams(thisTrial,20);
    
    %% detect perturbations
    if MyParams(thisTrial,26)>1 % was a perturbed trial
        switch MyParams(thisTrial,26)
            case 2 % fake zone
                MyData(f,11) = MyParams(thisTrial,28);
                MyData(f,12) = MyParams(thisTrial,30);
            case 3 % to detect NoOdor trials
                MyData(f,11) = 300;
                MyData(f,12) = 0;
            case 4 % flip mapping
                MyData(f,11) = 400;
                MyData(f,12) = 0;
            case {5,6,7} % location offset
                MyData(f,11) = 100*MyParams(thisTrial,26);
                MyData(f,12) = MyParams(thisTrial,27);
            case 8
                MyData(f,11) = 100*MyParams(thisTrial,26);
                MyData(f,12) = MyParams(thisTrial,27);
            case 9
                MyData(f,11) = 100*MyParams(thisTrial,26);
            case 10
                MyData(f,11) = 100*MyParams(thisTrial,26);
            case 13
                MyData(f,11) = 100*MyParams(thisTrial,26);
        end
    end
    
    %% detect block shift trials
    if MyParams(thisTrial,23)~=121 % was a perturbed trial
        MyData(f,11) = 100*11;
        MyData(f,12) = MyParams(thisTrial,23)-121;
    end
end

%% convert trial_ON column to odor IDs
% column number = 6 in MyData
for odor = 1:4
    f = find((MyData(:,6)>=odor^2) & (MyData(:,6)<(odor+1)^2));
    MyData(f,6) = odor;
end

%% cheat: to compensate for code bug for No odor trials
if isempty(strfind(FileName,'LR'))
if any(MyParams(:,2)==0) && ~any(MyData(:,6)>=4^2)
    % cheat to prevent last trial from being NoOdor Trial
    if MyParams(end,2) == 0
        MyParams(end,:) = [];
    end
    % extra hack to figure out when the odor was on if odor ID = 0
    NoOdorTrials(:,1) = MyParams(find(MyParams(:,2)==0),1);
    NoOdorTrials(:,2) = MyParams(find(MyParams(:,2)==0)+1,1);
    NoOdorTrials(:,3) = find(MyParams(:,2)==0);
    
    if size(NoOdorTrials,1)>0
        for thisTrial = 1:size(NoOdorTrials,1)
            indices = find((MyData(:,1)>NoOdorTrials(thisTrial,1)) & (MyData(:,1)<NoOdorTrials(thisTrial,2)));
            trialthreshold = MyParams(NoOdorTrials(thisTrial,3),11);
            trialhold = round(MyParams(NoOdorTrials(thisTrial,3),13))/2; % convert to samples
            thistriallever = MyData(indices,4);
            thistriallever(thistriallever<trialthreshold) = 0;
            thistriallever(thistriallever>=trialthreshold) = 1;
            triggerstart = find(diff(thistriallever)==1);
            triggerstop = find(diff(thistriallever)==-1);
            m = 1;
            while m<=min([numel(triggerstart),numel(triggerstop)])
                if (triggerstop(m)-triggerstart(m)+1)>=trialhold
                    indices(1:triggerstop(m)-1,:) = [];
                    MyData(indices,6) = 4; % odor 4
                    break;
                end
                m = m + 1;
            end
        end
    end
end
end

%% get list of target zones used
TargetZones = unique(MyParams(:,18:20),'rows');
FakeTargetZones = unique(MyParams(:,26:28),'rows');

%% Sanity checks
foo = FakeTargetZones;
foo(:,2) = foo(:,2) - foo(:,1);
FakeTargetZones(find((foo(:,2)==0)&(foo(:,1)<20)&(foo(:,1)>0)),:) = [];

end