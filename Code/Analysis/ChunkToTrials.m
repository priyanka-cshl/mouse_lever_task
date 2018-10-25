% organize the session data into a cell array of trials
function [Traces, TrialInfo, TargetZones] = ChunkToTrials(MyData, TargetZones, sessionstart, sessionstop)
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
    
    if any(find(MyData(TrialOn,1)<sessionstart))
        TrialOff(find(MyData(TrialOn,1)<sessionstart),:) = [];
        TrialOn(find(MyData(TrialOn,1)<sessionstart),:) = [];
    end
    
    if any(find(MyData(TrialOn,1)>sessionstop))
        TrialOff(find(MyData(TrialOn,1)>sessionstop),:) = [];
        TrialOn(find(MyData(TrialOn,1)>sessionstop),:) = [];
    end
    
    % Crunch data trial-by-trial
    LeverCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
    MotorCol = find(cellfun(@isempty,regexp(WhatsMyData','MotorPosition'))==0);
    EncoderCol = find(cellfun(@isempty,regexp(WhatsMyData','RotaryEncoder'))==0);
    HomeCol = find(cellfun(@isempty,regexp(WhatsMyData','HomeSensor'))==0);
    LickCol = find(cellfun(@isempty,regexp(WhatsMyData','Licks'))==0);
    RewardCol = find(cellfun(@isempty,regexp(WhatsMyData','Water'))==0);
    TZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InTargetZone'))==0);
    RZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InRewardZone'))==0);
    RespCol = find(cellfun(@isempty,regexp(WhatsMyData','Respiration'))==0);
    
    for t = 1:length(TrialOn)
        
        %% populate two cell arays - TrialInfo and Lever and Motor
        Lever(t) = { MyData(TrialOn(t):TrialOff(t), LeverCol) };
        Motor(t) = { MyData(TrialOn(t):TrialOff(t), MotorCol) };
        Respiration(t) = { MyData(TrialOn(t):TrialOff(t), RespCol) };
        Licks(t) = { MyData(TrialOn(t):TrialOff(t), LickCol) };
        
        TrialInfo.Timestamps(t,:) = MyData([TrialOn(t) TrialOff(t)],1);
        TrialInfo.TimeIndices(t,:) = [TrialOn(t) TrialOff(t)];
        TrialInfo.Odor(t,1) = mode( MyData(TrialOn(t):TrialOff(t), TrialCol) );
        TrialInfo.TargetZoneType(t,1) = find(TargetZones(:,1) == mode( MyData(TrialOn(t):TrialOff(t), 2) ),1);
        
        % check the 10 samples before trial start to verify if the transfer
        % function was inverted in this trial
        TrialInfo.TransferFunctionLeft(t,1) = (MyData(TrialOn(t)-1, MotorCol)>0);
        
        TrialInfo.Reward(t) = { find( diff( MyData(TrialOn(t):TrialOff(t), RewardCol) )==1 ) };
        TrialInfo.Duration(t,1) = TrialOff(t) - TrialOn(t) + 1;
        
        % Calculate all stay times
        TrialInfo.StayTime(t) = {  find( diff( [ MyData(TrialOn(t):TrialOff(t), TZoneCol); 0] )==-1 ) - find( diff( [0; MyData(TrialOn(t):TrialOff(t), TZoneCol)] )==1 ) + 1 };
        TrialInfo.StayTimeStart(t) = { find( diff( [0; MyData(TrialOn(t):TrialOff(t), TZoneCol)] )==1 ) };
        TrialInfo.TrialID(t) = t; % original trial ID - some trials may get deleted because of weird target zones
        
        % perturbations
        WhichPerturbation = mode( MyData(TrialOn(t):TrialOff(t), 11) );
        PerturbationValue = mode( MyData(TrialOn(t):TrialOff(t), 12) );
        
        if WhichPerturbation
            if WhichPerturbation < 100 % Fake target zone
                if isempty(find(TargetZones(:,2) == PerturbationValue))
                    TrialInfo.Perturbation(t,:) = [2 PerturbationValue];
                else
                    TrialInfo.Perturbation(t,:) = [2 find(TargetZones(:,2) == PerturbationValue)];
                end
            else
                switch WhichPerturbation
                    case 300 % No Odor
                        TrialInfo.Perturbation(t,:) = [3 0];
                    case 400 
                        TrialInfo.Perturbation(t,:) = [4 0];
                    case 500
                        TrialInfo.Perturbation(t,:) = [WhichPerturbation/100 PerturbationValue];
                    case 600
                        TrialInfo.Perturbation(t,:) = [WhichPerturbation/100 PerturbationValue];
                        TrialInfo.PerturbationStart(t) = find( diff([ MyData(TrialOn(t):TrialOff(t), RZoneCol); 0] )==1);
                        TrialInfo.FeedbackStart(t) = find( diff([ MyData(TrialOn(t):TrialOff(t), RZoneCol); 0] )==-1);
                        % get targetzone stay times for this trial
                        tempstays = cell2mat(TrialInfo.StayTimeStart(t));
                        tempstaytimes = cell2mat(TrialInfo.StayTime(t));
                        % find tzone stays after odor offset
                        foo = find(tempstays>TrialInfo.PerturbationStart(t));
                        if ~isempty(foo)
                            TrialInfo.OffsetStays = {tempstaytimes(foo)};
                            tempstays(foo,:) = [];
                            tempstaytimes(foo,:) = [];
                            TrialInfo.StayTime(t) = {tempstays};
                            TrialInfo.StayTimeStart(t) = {tempstaytimes};
                        end
                        
                end
            end
        else
            TrialInfo.Perturbation(t,:) = [0 0];
        end
        
        
        
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
    Licks(:,todelete) = [];
    
    TrialInfo.Timestamps(todelete,:) = [];
    TrialInfo.TimeIndices(todelete,:) = [];
    TrialInfo.Odor(todelete,:) = [];
    TrialInfo.TargetZoneType(todelete,:) = [];
    TrialInfo.TransferFunctionLeft(todelete,:) = [];
    TrialInfo.Reward(:,todelete) = [];
    TrialInfo.Duration(:,todelete) = [];
    TrialInfo.StayTime(:,todelete) = [];
    TrialInfo.StayTimeStart(:,todelete) = [];
    TrialInfo.TrialID(:,todelete) = [];
    TrialInfo.Perturbation(todelete,:) = [];
    TrialInfo.Success(todelete,:) = [];

    Traces.Lever = Lever;
    Traces.Motor = Motor;
    Traces.Licks = Licks;
    Traces.Respiration = Respiration;
end