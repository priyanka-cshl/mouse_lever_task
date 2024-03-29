% organize the session data into a cell array of trials
function [Lever, Motor, TrialInfo, TargetZones, Respiration] = ChunkUpTrials(MyData, TargetZones,  FakeTargetZones)
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
        
    % Crunch data trial-by-trial
    LeverCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
    RewardCol = find(cellfun(@isempty,regexp(WhatsMyData','Water'))==0);
    TZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InTargetZone'))==0);
    if size(MyData,2)>12
        EncoderCol = find(cellfun(@isempty,regexp(WhatsMyData','RotaryEncoder'))==0);
        MotorCol = find(cellfun(@isempty,regexp(WhatsMyData','MotorPosition'))==0);
        HomeCol = find(cellfun(@isempty,regexp(WhatsMyData','HomeSensor'))==0);
        RespCol = find(cellfun(@isempty,regexp(WhatsMyData','Respiration'))==0);
    end
    
    for t = 1:length(TrialOn)
        
        %% populate two cell arays - TrialInfo and Lever and Motor
        Lever(t) = { MyData(TrialOn(t):TrialOff(t), LeverCol) };
        Motor(t) = { MyData(TrialOn(t):TrialOff(t), MotorCol) };
        Respiration(t) = { MyData(TrialOn(t):TrialOff(t), RespCol) };
        
        TrialInfo.Timestamps(t,:) = MyData([TrialOn(t) TrialOff(t)],1);
        TrialInfo.TimeIndices(t,:) = [TrialOn(t) TrialOff(t)];
        TrialInfo.Odor(t,1) = mode( MyData(TrialOn(t):TrialOff(t), TrialCol) );
        TrialInfo.TargetZoneType(t,1) = find(TargetZones(:,1)==mode( MyData(TrialOn(t):TrialOff(t), 2) ),1);
        
        % check the 10 samples before trial start to verify if the transfer
        % function was inverted in this trial
        TrialInfo.TransferFunctionLeft(t,1) = (MyData(TrialOn(t)-1, MotorCol)>0);
        
        TrialInfo.Reward(t) = { find( diff( MyData(TrialOn(t):TrialOff(t), RewardCol) )==1 ) };
        TrialInfo.Length(t) = TrialOff(t) - TrialOn(t) + 1;
        
        % perturbation - fake zone
        WhichFakeZone = FakeTargetZones(find(FakeTargetZones(:,1)==mode( MyData(TrialOn(t):TrialOff(t), 11) )),2);
        %TrialInfo.FakeZone(t) = {find(TargetZones(:,1)==mode( MyData(TrialOn(t):TrialOff(t), 11) ))};
        if isempty(find(TargetZones(:,2)==WhichFakeZone))
            TrialInfo.FakeZone(t) = {WhichFakeZone};
        else
            TrialInfo.FakeZone(t) = {find(TargetZones(:,2)==WhichFakeZone)};
        end
        % Calculate all stay times
        TrialInfo.StayTime(t) = {  find( diff( [ MyData(TrialOn(t):TrialOff(t), TZoneCol); 0] )==-1 ) - find( diff( [0; MyData(TrialOn(t):TrialOff(t), TZoneCol)] )==1 ) + 1 };
        TrialInfo.StayTimeStart(t) = { find( diff( [0; MyData(TrialOn(t):TrialOff(t), TZoneCol)] )==1 ) };
        TrialInfo.TrialID(t) = t; % original trial ID - some trials may get deleted because of weird target zones
        
    end
    
    % successes and failures
    TrialInfo.Success = ~cellfun(@isempty, TrialInfo.Reward)';
    for i = 1:size(TargetZones,1)
        TargetZones(i,4) = numel( find(TrialInfo.TargetZoneType == i));
    end
   
    f = find(TargetZones(:,1)==3); % buggy zone definition
    
    todelete = [];
    for i = 1:numel(f)
        todelete = [todelete; find(TrialInfo.TargetZoneType==f(i))];
    end
        
    Lever(:,todelete) = [];
    Motor(:,todelete) = [];
    Respiration(:,todelete) = [];
    
    TrialInfo.Odor(todelete,:) = [];
    TrialInfo.TargetZoneType(todelete,:) = [];
    TrialInfo.Reward(:,todelete) = [];
    TrialInfo.Length(:,todelete) = [];
    TrialInfo.FakeZone(:,todelete) = [];
    TrialInfo.StayTime(:,todelete) = [];
    TrialInfo.StayTimeStart(:,todelete) = [];
    TrialInfo.TrialID(:,todelete) = [];
    TrialInfo.Success(todelete,:) = [];
    TrialInfo.Timestamps(todelete,:) = [];
    TrialInfo.TimeIndices(todelete,:) = [];
    %TargetZones(f,:) = [];
    
end