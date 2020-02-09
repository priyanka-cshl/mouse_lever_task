% organize the session data into a cell array of trials
function [Traces, TrialInfo, Replay, ReplayInfo, TargetZones] = ParseReplayTrials(MyData, MySettings, TargetZones, sessionstart, sessionstop)

global SampleRate; % = 500; % samples/second

if nargin < 4
    sessionstart = 0;
    sessionstop = max(MyData(:,1));
elseif nargin < 5
    sessionstop = max(MyData(:,1));
end

% cautionary - ignore erratic target zones
if size(TargetZones,1)>12
    disp('CAUTION: session contains more than 12 target zones');
    TargetZonesTemp = TargetZones;
    f = find(round(TargetZones(:,1) - TargetZones(:,3))~=1);
    TargetZones(f,:) = [];
end

% Get Column IDs
TrialCol = find(cellfun(@isempty,regexp(WhatsMyData','Trial'))==0);
LeverCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
MotorCol = find(cellfun(@isempty,regexp(WhatsMyData','MotorPosition'))==0);
EncoderCol = find(cellfun(@isempty,regexp(WhatsMyData','RotaryEncoder'))==0);
HomeCol = find(cellfun(@isempty,regexp(WhatsMyData','HomeSensor'))==0);
LickCol = find(cellfun(@isempty,regexp(WhatsMyData','Licks'))==0);
RewardCol = find(cellfun(@isempty,regexp(WhatsMyData','Water'))==0);
TZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InTargetZone'))==0);
RZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InRewardZone'))==0);
RespCol = find(cellfun(@isempty,regexp(WhatsMyData','Respiration'))==0);

%% Get Trial ON-OFF timestamps
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

%% Replay related

% find the stretch of open loop recording trials
OL_Blocks  = numel(find(diff(MySettings(:,32))==1));
OL_Starts  = MySettings(find(diff(MySettings(:,32))== 1)+1,1);
OL_Stops   = MySettings(find(diff(MySettings(:,32))==-1)+1,1);

Replay_Starts = MySettings(find(diff(MySettings(:,32))== 2)+1,1);
%Replay_Starts(5) = 1661.4;

for thisBlock = 1:OL_Blocks
    % find first trial after open loop recording flag was turned to 1
    FirstTrial = find(TrialOn>OL_Starts(thisBlock)*SampleRate,1,'first');
    LastTrial = find(TrialOn<OL_Stops(thisBlock)*SampleRate,1,'last');
    
    % Get traces for the recorded open loop trials
    for thisTrial = FirstTrial:LastTrial
        start_offset = 1;
        start_idx = TrialOn(thisTrial) - start_offset*SampleRate;
        stop_idx = TrialOn(thisTrial+1) - start_offset*SampleRate; % until the next trial start
        
        % Extract traces
        Traces.Lever(thisTrial-FirstTrial+1)  = { MyData(start_idx:stop_idx, LeverCol) };
        Traces.Motor(thisTrial-FirstTrial+1)  = { MyData(start_idx:stop_idx, MotorCol) };
        Traces.Encoder(thisTrial-FirstTrial+1)  = { MyData(start_idx:stop_idx, EncoderCol) };
        Traces.Sniffs(thisTrial-FirstTrial+1) = { MyData(start_idx:stop_idx, RespCol) };
        Traces.Licks(thisTrial-FirstTrial+1)  = { MyData(start_idx:stop_idx, LickCol) };
        
        % Extract Events
        TrialInfo.TrialID(thisTrial-FirstTrial+1) = thisTrial; % original trial ID - some trials may get deleted because of weird target zones
        
        % Trial Timestamps
        thisTrialIdx = [TrialOn(thisTrial) TrialOff(thisTrial)];
        TrialInfo.SessionIndices(thisTrial-FirstTrial+1,:) = thisTrialIdx;
        TrialInfo.SessionTimestamps(thisTrial-FirstTrial+1,:) = MyData(thisTrialIdx,1); % actual timestamps of trial start and end
        TrialInfo.Timestamps(thisTrial-FirstTrial+1,:) = MyData(thisTrialIdx,1) - MyData(start_idx,1); % in seconds, relative to trace start
        TrialInfo.TimeIndices(thisTrial-FirstTrial+1,:) = thisTrialIdx - start_idx;
        TrialInfo.Duration(thisTrial-FirstTrial+1,1) = (diff(thisTrialIdx) + 1)/SampleRate; % in seconds
        
        TrialInfo.Valid(thisTrial-FirstTrial+1,1) = 0;
        
        % Which odor
        TrialInfo.Odor(thisTrial-FirstTrial+1,1) = mode(MyData(thisTrialIdx(1):thisTrialIdx(2),TrialCol));

        % Odor ON timestamp
        thisTrialInZone = find(diff(MyData(start_idx:thisTrialIdx(1), RZoneCol))==-1);
        if ~isempty(thisTrialInZone)
            TrialInfo.OdorStart(thisTrial-FirstTrial+1,1) = thisTrialInZone(end);
        else
            TrialInfo.OdorStart(thisTrial-FirstTrial+1,1) = NaN;
        end
        LeverTemp = MyData(start_idx:thisTrialIdx(1), LeverCol);
        LeverTemp(LeverTemp<4.8) = 0;
        LeverTemp(LeverTemp>0) = 1;
        Initiations = [find(diff([0; LeverTemp; 0])==1) find(diff([0; LeverTemp; 0])==-1)-1];
        TriggerHold = MySettings(thisTrial,13); % in msec
        TriggerHold = floor(TriggerHold*SampleRate/1000); % in samples
        OdorStart = find((Initiations(:,2)-Initiations(:,1))>=TriggerHold,1,'first');
        if isempty(OdorStart)
            OdorStart = 1;
        end
        TrialInfo.OdorStart(thisTrial-FirstTrial+1,2) = Initiations(OdorStart,1) + TriggerHold - 1;
        TrialInfo.OdorStart(thisTrial-FirstTrial+1,:) = TrialInfo.OdorStart(thisTrial-FirstTrial+1,:)/SampleRate; % convert to seconds
        
        
        % Which TargetZone
        if ~isempty(find(TargetZones(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1))
            TrialInfo.TargetZoneType(thisTrial-FirstTrial+1,1) = ...
                find(TargetZones(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1);
        else
            thiszonetarget = TargetZonesTemp(find(TargetZonesTemp(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1),2);
            TrialInfo.TargetZoneType(thisTrial-FirstTrial+1,1) = find(TargetZones(:,2) == thiszonetarget);
        end
        
        % TF left or right?
        % check the 10 samples before trial start to verify if the transfer
        % function was inverted in this trial
        TrialInfo.TransferFunctionLeft(thisTrial-FirstTrial+1,1) = (MyData(TrialOn(thisTrial)-1, MotorCol)>0);
        
        % Reward timestamps
        thisTrialRewards = find(diff(MyData(start_idx:stop_idx,RewardCol))==1); % indices w.r.t. to trace start
        thisTrialRewards = thisTrialRewards/SampleRate; % convert to seconds
        % force the reward time stamps that were before trial start to -ve
        thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial-FirstTrial+1,1)) = ...
            -1*thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial-FirstTrial+1,1));
        if ~isempty(thisTrialRewards)
            TrialInfo.Reward(thisTrial-FirstTrial+1) = { thisTrialRewards };
            TrialInfo.Success(thisTrial-FirstTrial+1,1) = any(thisTrialRewards>0); % successes and failures
        else
            TrialInfo.Reward(thisTrial-FirstTrial+1) = { [] };
            TrialInfo.Success(thisTrial-FirstTrial+1,1) = 0; % successes and failures
        end
        
        TrialInfo.Perturbation(thisTrial-FirstTrial+1,:) = [0 0];
    end
    
    % Get traces for the replay of the same block
    if thisBlock<OL_Blocks
        ReplayTrials = find(Replay_Starts<OL_Starts(thisBlock+1));
    else
        ReplayTrials = find(Replay_Starts>OL_Starts(thisBlock));
    end
    
    for thisReplay = 1:numel(ReplayTrials)
        %MyTrial = find(TrialOn>Replay_Starts(thisReplay)*SampleRate,1,'first');
        MyTrial = find(TrialOn>(Replay_Starts(ReplayTrials(thisReplay))*SampleRate),1,'first');
        
        start_idx = TrialOn(MyTrial) - start_offset*SampleRate;
        %stop_idx = TrialOn(thisTrial+1) - start_offset*SampleRate; % until the next trial start
        
        for thisTrial = 1:numel(TrialInfo.TrialID)
            stop_idx = start_idx + length(Traces.Lever{thisTrial}) - 1;
            
            % Extract traces
            Replay.Lever(thisTrial,thisReplay)  = { MyData(start_idx:stop_idx, LeverCol) };
            Replay.Motor(thisTrial,thisReplay)  = { MyData(start_idx:stop_idx, MotorCol) };
            Replay.Sniffs(thisTrial,thisReplay) = { MyData(start_idx:stop_idx, RespCol) };
            Replay.Licks(thisTrial,thisReplay)  = { MyData(start_idx:stop_idx, LickCol) };
            
            % Extract Events
            ReplayInfo.TrialID(thisTrial,thisReplay) = MyTrial; % original trial ID - some trials may get deleted because of weird target zones
            
            % Reward timestamps
            thisTrialRewards = find(diff(MyData(start_idx:stop_idx,RewardCol))==1); % indices w.r.t. to trace start
            thisTrialRewards = thisTrialRewards/SampleRate; % convert to seconds
            % force the reward time stamps that were before trial start to -ve
            thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial,1)) = ...
                -1*thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial,1));
            if ~isempty(thisTrialRewards)
                ReplayInfo.Reward(thisTrial,thisReplay) = { thisTrialRewards };
            else
                ReplayInfo.Reward(thisTrial,thisReplay) = { [] };
            end
        
            start_idx = start_idx + length(Traces.Lever{thisTrial}) + 2;
        end
        
    end
end

end