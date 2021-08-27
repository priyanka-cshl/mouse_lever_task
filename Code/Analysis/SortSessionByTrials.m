% organize the session data into a cell array of trials
function [Lever,TrialInfo, TargetZones] = SortSessionByTrials(MyData)
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
        TrialInfo.TrialID(t) = t; % original trial ID - some trials may get deleted because of weird target zones
    end
    
    % successes and failures
    TrialInfo.Success = ~cellfun(@isempty, TrialInfo.Reward)';
    for i = 1:size(TargetZones,1)
        TargetZones(i,3) = numel( find(TrialInfo.TargetZoneType == i));
    end
   
    f = find(TargetZones(:,1)==3); % buggy zone definition
    
    todelete = [];
    for i = 1:numel(f);
        todelete = [todelete; find(TrialInfo.TargetZoneType==f(i))];
    end
        
    Lever(:,todelete) = [];
    
    TrialInfo.Odor(todelete,:) = [];
    TrialInfo.TargetZoneType(todelete,:) = [];
    TrialInfo.Reward(:,todelete) = [];
    TrialInfo.Length(:,todelete) = [];
    TrialInfo.FakeZone(:,todelete) = [];
    TrialInfo.StayTime(:,todelete) = [];
    TrialInfo.StayTimeStart(:,todelete) = [];
    TrialInfo.TrialID(:,todelete) = [];
    TrialInfo.Success(todelete,:) = [];
    %TargetZones(f,:) = [];
    
end