% organize the session data into a cell array of trials
function [Lever,TrialInfo, TargetZones] = DetectChangeInZoneLimits(MyData,Params)
    % column ID for trial column
    TrialCol = find(cellfun(@isempty,regexp(WhatsMyData','Trial'))==0);
    TrialColumn = MyData(:,TrialCol);
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
    
    % find param updates that happened during ITIs
    X = diff(Params(:,18:20));
    X(X~=0) = 1;
    f = find(X(:,2)-X(:,1)==-1);
    
    
    
    T = [[0; MyData(TrialOff(1:end-1),1)] MyData(TrialOn,1)];
    for i = 1:size(T,1)
        MultipleUpdates(i) = numel(intersect(find(Params(:,1)>=T(i,1)),find(Params(:,1)<T(i,2))));
    end
    
    f = find(MultipleUpdates>1); 
    f(find(f)==1) = [];
    for i = 1:length(f)
        idx = intersect(find(Params(:,1)>=T(f(i),1)),find(Params(:,1)<T(f(i),2)));
    end
        
    
    
    % get a list of unique Target Zone conditions
    [x,y] = unique(MyData(TrialOn(1):end,2)); % a hack to get rid of crappy values in the beginning
    for i = 1:length(x)
        TargetZones(i,:) = MyData(TrialOn(1) - 1 + find(MyData(TrialOn(1):end,2)==x(i),1), [2 3] );
    end
    
    % Crunch data trial-by-trial
    LeverCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
    RewardCol = find(cellfun(@isempty,regexp(WhatsMyData','Water'))==0);
    TZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InTargetZone'))==0);
    
    for t = 1:length(TrialOn)
        % populate two cell arays - TrialInfo and Lever
        Lever(t) = { MyData(TrialOn(t):TrialOff(t), LeverCol) };
        TrialInfo.Odor(t,1) = mode( MyData(TrialOn(t):TrialOff(t), TrialCol) );
        TrialInfo.TargetZoneType(t,1) = find(TargetZones(:,1)==mode( MyData(TrialOn(t):TrialOff(t), 2) ));
        TrialInfo.Reward(t) = { find( diff( MyData(TrialOn(t):TrialOff(t), RewardCol) )==1 ) };
        TrialInfo.Length(t) = TrialOff(t) - TrialOn(t) + 1;
        % perturbation - fake zone
        TrialInfo.FakeZone(t) = {find(TargetZones(:,1)==mode( MyData(TrialOn(t):TrialOff(t), 11) ))};

        % Calculate all stay times
        TrialInfo.StayTime(t) = {  find( diff( [ MyData(TrialOn(t):TrialOff(t), TZoneCol); 0] )==-1 ) - find( diff( [0; MyData(TrialOn(t):TrialOff(t), TZoneCol)] )==1 ) + 1 };
        TrialInfo.StayTimeStart(t) = { find( diff( [0; MyData(TrialOn(t):TrialOff(t), TZoneCol)] )==1 ) };
    end
    
    % successes and failures
    TrialInfo.Success = ~cellfun(@isempty, TrialInfo.Reward)';
    for i = 1:size(TargetZones,1)
        TargetZones(i,3) = numel( find(TrialInfo.TargetZoneType == i));
    end    
end