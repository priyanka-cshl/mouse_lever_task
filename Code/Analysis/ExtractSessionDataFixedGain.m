% test script to extract behavior data and replot session
% for animals trained on the fixed gain version of the task (post 08.2018)

function [MyData, params, TargetZones, FakeTargetZones] = ExtractSessionDataFixedGain(FileName, PIDflag)
if nargin<2
    PIDflag = 0;
end

% load the file
Temp = load(FileName,'session_data');
[nrows, ncols] = size(Temp.session_data.trace);

if PIDflag
    % [PID* RotaryEncoder TrialON InTargetZone InRewardZone Rewards
    % Licks]
    % * PID was acquired on the lick piezo channel
    MyData = Temp.session_data.trace(:,[6 3 7:11]);
else
    % [Lever RotaryEncoder TrialON InTargetZone InRewardZone Rewards
    % Licks HomeSensor Camera1 Camera2]
    MyData = Temp.session_data.trace(:,[1 3 7:11]);
    
    % add 3 cols in the beginning [timestamps TZoneHighLim TZoneLowLim ...
    % add 2 cols in the end [FZoneHighLim FZoneLowLim]
    MyData = horzcat(Temp.session_data.timestamps, zeros(nrows,2), MyData, zeros(nrows,2));
    
    % append motor location
    MyData(:,13) = Temp.session_data.trace(:,4);
%     % fix a scaling bug in some versions of the fix speed TF code (used during nov, dec 2017)
%     if isequal(mode(Temp.session_data.params(:,21:23)),[14 121 66])
%         MyData(:,end+1) = mode(Temp.session_data.params(:,22))*Temp.session_data.trace(:,4)/sum(mode(Temp.session_data.params(:,21:23)));
%     end
    
    if find(ismember(Temp.session_data.trace_legend,'homesensor'))
        whichcol = find(ismember(Temp.session_data.trace_legend,'homesensor'));
        MyData(:,14) = Temp.session_data.trace(:,whichcol);
    end
    
    if find(ismember(Temp.session_data.trace_legend,'respiration'))
        whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
        MyData(:,15) = Temp.session_data.trace(:,whichcol);
    end
    
    if find(ismember(Temp.session_data.trace_legend,'camerasync'))
        whichcol = find(ismember(Temp.session_data.trace_legend,'camerasync'));
        MyData(:,16) = Temp.session_data.trace(:,whichcol);
    end
    
    if size(Temp.session_data.trace,2)>whichcol
        whichcol = whichcol + 1;
        MyData(:,17) = Temp.session_data.trace(:,whichcol);
    end
    
end

%% clean up params table
%% HACK - in some versions of the code, params were written to
%% disc with -ve timestamp before an actual update happened
% only start with entries that have non-zero timestamps
Temp.session_data.params(1: find(Temp.session_data.params(:,1)==0,1,'last')-1,:) = [];
% if timestamps are negative - ignore those
Temp.session_data.params(find(Temp.session_data.params(:,1)<0),:) = [];

%% get target zone values
for t = 1:size(Temp.session_data.params,1)
    if t < size(Temp.session_data.params,1)
        f = find((MyData(:,1)>=Temp.session_data.params(t,1)) &...
            (MyData(:,1)<Temp.session_data.params(t+1,1)));
    else
        f = find(MyData(:,1)>=Temp.session_data.params(end,1));
    end
    MyData(f,2) = Temp.session_data.params(t,18);
    MyData(f,3) = Temp.session_data.params(t,20);
    % detect perturbations
    if size(Temp.session_data.legends,2)>=35
        if Temp.session_data.params(t,26)>1
            switch Temp.session_data.params(t,26)
                case 2 % fake zone
                    MyData(f,11) = Temp.session_data.params(t,28);
                    MyData(f,12) = Temp.session_data.params(t,30);
                case 3 % to detect NoOdor trials
                    MyData(f,11) = 300;
                    MyData(f,12) = 0;
                case 4 % flip mapping
                    MyData(f,11) = 400;
                    MyData(f,12) = 0;
                case {5,6,7} % location offset
                    MyData(f,11) = 100*Temp.session_data.params(t,26);
                    MyData(f,12) = Temp.session_data.params(t,27);
                case 8
                    MyData(f,11) = 100*Temp.session_data.params(t,26);
                    MyData(f,12) = Temp.session_data.params(t,27);
                case 9
                    MyData(f,11) = 100*Temp.session_data.params(t,26);
                case 10
                    MyData(f,11) = 100*Temp.session_data.params(t,26);
            end
        end
    else
        if Temp.session_data.params(t,29) == 1 % to detect mapping flip perturbations
            MyData(f,11) = 100;
            MyData(f,12) = 100;
        elseif  Temp.session_data.params(t,31) == 1 % offset perturbations
            MyData(f,11) = Temp.session_data.params(t,9);
            MyData(f,12) = Temp.session_data.params(t,9);
        else % fake target zone perturbations
            MyData(f,11) = Temp.session_data.params(t,26);
            MyData(f,12) = Temp.session_data.params(t,28);
        end
    end
end

%% convert trial_ON column to odor IDs
% column number = 6 in MyData
for odor = 1:4
    f = find((MyData(:,6)>=odor^2) & (MyData(:,6)<(odor+1)^2));
    MyData(f,6) = odor;
end

%% extract session settings
params = Temp.session_data.params;

%% cheat to compensate for code bug for No odor trials
if any(params(:,2)==0) && ~any(MyData(:,6)>=4^2)
    % cheat to prevent last trial from being NoOdor Trial
    if params(end,2) == 0
        params(end,:) = [];
    end
    % extra hack to figure out when the odor was on if odor ID = 0
    NoOdorTrials(:,1) = params(find(params(:,2)==0),1);
    NoOdorTrials(:,2) = params(find(params(:,2)==0)+1,1);
    NoOdorTrials(:,3) = find(params(:,2)==0);
    
    if size(NoOdorTrials,1)>0
        for t = 1:size(NoOdorTrials,1)
            indices = find((MyData(:,1)>NoOdorTrials(t,1)) & (MyData(:,1)<NoOdorTrials(t,2)));
            trialthreshold = params(NoOdorTrials(t,3),11);
            trialhold = round(params(NoOdorTrials(t,3),13))/2; % convert to samples
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

%% get list of target zones used
TargetZones = unique(params(:,18:20),'rows');
FakeTargetZones = unique(params(:,26:28),'rows');

if size(Temp.session_data.legends,2)<35
    if any(find(params(:,29)))
        FakeTargetZones = [FakeTargetZones; [100 100 100]];
    end
    if any(find(params(:,31)))
        foo = unique(MyData(:,[11]),'rows');
        foo(find(foo==0),:) = [];
        FakeTargetZones = [FakeTargetZones; repmat(foo, 1, 3)];
    end
end

%% Sanity checks
foo = FakeTargetZones;
foo(:,2) = foo(:,2) - foo(:,1);
FakeTargetZones(find((foo(:,2)==0)&(foo(:,1)<20)&(foo(:,1)>0)),:) = [];

end