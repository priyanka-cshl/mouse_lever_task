% organize the session data into a cell array of trials
function [Traces, TrialInfo, TargetZones] = ParseTrials(MyData, MySettings, TargetZones, sessionstart, sessionstop)

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

% Crunch data trial-by-trial
for thisTrial = 1:length(TrialOn)
    
    % pull down all flags
    trialflag = 0;
    
    %% 1: extract continuous traces for lever, motor position, licks and sniffs
    
    if thisTrial > 1
        start_offset = 0;
        start_idx = TrialOff(thisTrial-1); % start from the end of the previous trial
    else % very first trial
        start_offset = -1; % start one second before trial start
        start_idx = TrialOn(thisTrial) - min(-start_offset*SampleRate,TrialOn(thisTrial)-1);
        trialflag = -1; % ignore this trial
    end
    
    stop_idx = TrialOff(thisTrial); % until end of current trial
    
    if thisTrial < length(TrialOn) 
    else % last trial
        trialflag = -1;
    end
    
    % Extract traces
    Traces.Lever(thisTrial) = { MyData(start_idx:stop_idx, LeverCol) };
    Traces.Motor(thisTrial) = { MyData(start_idx:stop_idx, MotorCol) };
    Traces.Sniffs(thisTrial) = { MyData(start_idx:stop_idx, RespCol) };
    Traces.Licks(thisTrial) = { MyData(start_idx:stop_idx, LickCol) };
    
    % Extract Events
    TrialInfo.TrialID(thisTrial) = thisTrial; % original trial ID - some trials may get deleted because of weird target zones
    
    % Trial Timestamps
    thisTrialIdx = [TrialOn(thisTrial) TrialOff(thisTrial)];
    TrialInfo.SessionTimestamps(thisTrial,:) = MyData(thisTrialIdx,1); % actual timestamps of trial start and end
    TrialInfo.Timestamps(thisTrial,:) = MyData(thisTrialIdx,1) - MyData(start_idx,1); % in seconds, relative to trace start
    TrialInfo.TimeIndices(thisTrial,:) = thisTrialIdx - start_idx;
    TrialInfo.Duration(thisTrial,1) = (diff(thisTrialIdx) + 1)/SampleRate; % in seconds
    
    % Flag invalid trials
    if (MyData(thisTrialIdx(1),1) < sessionstart) || (MyData(thisTrialIdx(1),1) > sessionstop)
        trialflag = -1;
    end
    TrialInfo.Valid(thisTrial,1) = trialflag;
    % Which odor
    TrialInfo.Odor(thisTrial,1) = mode(MyData(thisTrialIdx(1):thisTrialIdx(2),TrialCol));
    
    % Odor ON timestamp
    thisTrialInZone = find(diff(MyData(start_idx:thisTrialIdx, RZoneCol))==-1);
    if ~isempty(thisTrialInZone)
        TrialInfo.OdorStart(thisTrial,1) = thisTrialInZone(end);
    else
        TrialInfo.OdorStart(thisTrial,1) = NaN;
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
    TrialInfo.OdorStart(thisTrial,2) = Initiations(OdorStart,1) + TriggerHold - 1;
    TrialInfo.OdorStart(thisTrial,:) = TrialInfo.OdorStart(thisTrial,:)/SampleRate; % convert to seconds
    
    
    % Which TargetZone
    if ~isempty(find(TargetZones(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1))
        TrialInfo.TargetZoneType(thisTrial,1) = ...
            find(TargetZones(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1);
    else
        thiszonetarget = TargetZonesTemp(find(TargetZonesTemp(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1),2);
        TrialInfo.TargetZoneType(thisTrial,1) = find(TargetZones(:,2) == thiszonetarget);
    end
    
    % TF left or right?
    % check the 10 samples before trial start to verify if the transfer
    % function was inverted in this trial
    TrialInfo.TransferFunctionLeft(thisTrial,1) = (MyData(TrialOn(thisTrial)-1, MotorCol)>0);
    
    % Reward timestamps
    thisTrialRewards = find(diff(MyData(start_idx:stop_idx,RewardCol))==1); % indices w.r.t. to trace start
    thisTrialRewards = thisTrialRewards/SampleRate; % convert to seconds
    % force the reward time stamps that were before trial start to -ve
    thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial,1)) = ...
        -1*thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial,1));
    if ~isempty(thisTrialRewards)
        TrialInfo.Reward(thisTrial) = { thisTrialRewards };
        TrialInfo.Success = any(thisTrialRewards>0); % successes and failures
    else
        TrialInfo.Reward(thisTrial) = { [] };
        TrialInfo.Success = 0; % successes and failures
    end
    
    % Calculate all stay times
    thisTrialInZone = [find(diff([0;MyData(TrialOn(thisTrial):TrialOff(thisTrial), TZoneCol)])==1) ...
        find(diff([MyData(TrialOn(thisTrial):TrialOff(thisTrial), TZoneCol);0])==-1)]; % entry and exit indices w.r.t. Trial ON    
    thisTrialInZone = TrialInfo.Timestamps(thisTrial,1) + thisTrialInZone/SampleRate; % convert to seconds and offset w.r.t. trace start
    if ~isempty(thisTrialInZone)
        TrialInfo.InZone(thisTrial) = { thisTrialInZone };
    else
        TrialInfo.InZone(thisTrial) = { [] };
    end
    
    % perturbations
    WhichPerturbation = mode( MyData(TrialOn(thisTrial):TrialOff(thisTrial), 11) );
    PerturbationValue = mode( MyData(TrialOn(thisTrial):TrialOff(thisTrial), 12) );
    
    if WhichPerturbation
        if WhichPerturbation < 100 % Fake target zone
            if isempty(find(TargetZones(:,2) == PerturbationValue))
                TrialInfo.Perturbation(thisTrial,:) = [2 PerturbationValue];
            else
                TrialInfo.Perturbation(thisTrial,:) = [2 find(TargetZones(:,2) == PerturbationValue)];
            end
        else
            switch WhichPerturbation
                case 300 % No Odor
                    TrialInfo.Perturbation(thisTrial,:) = [3 0];
                case 400 % flip map
                    TrialInfo.Perturbation(thisTrial,:) = [4 0];
                case 500 % location offset I
                    TrialInfo.Perturbation(thisTrial,:) = [WhichPerturbation/100 PerturbationValue];
                    
                case {600, 700} % location offset II and III
                    if ~isempty(find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==1))
                        TrialInfo.Perturbation(thisTrial,:) = [WhichPerturbation/100 PerturbationValue];
                        TrialInfo.PerturbationStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==1);
                        TrialInfo.FeedbackStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1);
                        % convert to seconds w.r.t. trial start
                        TrialInfo.PerturbationStart(thisTrial) = TrialInfo.PerturbationStart(thisTrial)/SampleRate;
                        TrialInfo.FeedbackStart(thisTrial) = TrialInfo.FeedbackStart(thisTrial)/SampleRate;
                        % convert to seconds w.r.t. trace start
                        TrialInfo.PerturbationStart(thisTrial) = TrialInfo.PerturbationStart(thisTrial) + TrialInfo.Timestamps(thisTrial,1);
                        TrialInfo.FeedbackStart(thisTrial) = TrialInfo.FeedbackStart(thisTrial) + TrialInfo.Timestamps(thisTrial,1);
%                         % get targetzone stay times for this trial
%                         tempstays = cell2mat(TrialInfo.StayTimeStart(thisTrial));
%                         tempstaytimes = cell2mat(TrialInfo.StayTime(thisTrial));
%                         % find tzone stays after odor offset
%                         foo = find(tempstays>TrialInfo.PerturbationStart(thisTrial));
%                         if ~isempty(foo)
%                             TrialInfo.OffsetStays = {tempstaytimes(foo)};
%                             tempstays(foo,:) = [];
%                             tempstaytimes(foo,:) = [];
%                             TrialInfo.StayTime(thisTrial) = {tempstays};
%                             TrialInfo.StayTimeStart(thisTrial) = {tempstaytimes};
%                         end
                    end
                case 800 % gain change
                    TrialInfo.Perturbation(thisTrial,:) = [WhichPerturbation/100 PerturbationValue];
                case 900 % halts
                    if ~isempty(find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1))
                        TrialInfo.Perturbation(thisTrial,:) = [WhichPerturbation/100 PerturbationValue];
                        TrialInfo.FeedbackStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1);
                        
                        % get targetzone stay times for this trial
                        tempstays = cell2mat(TrialInfo.StayTimeStart(thisTrial));
                        tempstaytimes = cell2mat(TrialInfo.StayTime(thisTrial));
                        % find tzone stays after odor offset
                        foo = find(tempstays<TrialInfo.FeedbackStart(thisTrial));
                        if ~isempty(foo)
                            TrialInfo.TZoneStays = {tempstaytimes(foo)};
                            tempstays(foo,:) = [];
                            tempstaytimes(foo,:) = [];
                            TrialInfo.StayTime(thisTrial) = {tempstays};
                            TrialInfo.StayTimeStart(thisTrial) = {tempstaytimes};
                        end
                    end
                case 1000 % halts
                    if ~isempty(find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1))
                        TrialInfo.Perturbation(thisTrial,:) = [WhichPerturbation/100 PerturbationValue];
                        TrialInfo.PerturbationStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==1);
                        TrialInfo.FeedbackStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1);
                        
%                         % get targetzone stay times for this trial
%                         tempstays = cell2mat(TrialInfo.StayTimeStart(thisTrial));
%                         tempstaytimes = cell2mat(TrialInfo.StayTime(thisTrial));
%                         % find tzone stays after odor offset
%                         foo = find(tempstays<TrialInfo.FeedbackStart(thisTrial));
%                         if ~isempty(foo)
%                             TrialInfo.TZoneStays = {tempstaytimes(foo)};
%                             tempstays(foo,:) = [];
%                             tempstaytimes(foo,:) = [];
%                             TrialInfo.StayTime(thisTrial) = {tempstays};
%                             TrialInfo.StayTimeStart(thisTrial) = {tempstaytimes};
%                         end
                    end
                    
                case 1100 % block shift perturbations
                    TrialInfo.Perturbation(thisTrial,:) = [11 PerturbationValue];
                    
            end
        end
    else
        TrialInfo.Perturbation(thisTrial,:) = [0 0];
    end

end

% count trials of each target zone type
for i = 1:size(TargetZones,1)
    TargetZones(i,4) = numel( find(TrialInfo.TargetZoneType == i));
end

% sanity checks for buggy zone definitions - historical
f = find(TargetZones(:,1)==3); % buggy zone definition

if ~isempty(f)
    disp('CAUTION: session contains weird target zones');
    todelete = [];
    for i = 1:numel(f)
        todelete = [todelete; find(TrialInfo.TargetZoneType==f(i))];
    end
    
    
    Traces.Lever(todelete,:) = [];
    Traces.Motor(todelete,:) = [];
    Traces.Sniffs(todelete,:) = {};
    Traces.Licks(todelete,:) = {};
    
    TrialInfo.TrialID(:,todelete) = [];  
    TrialInfo.Valid(todelete,:) = [];
    TrialInfo.SessionTimestamps(todelete,:) = [];
    TrialInfo.Timestamps(todelete,:) = [];
    TrialInfo.TimeIndices(todelete,:) = [];
    TrialInfo.Duration(:,todelete) = [];
    
    TrialInfo.Odor(todelete,:) = [];
    TrialInfo.OdorStart(todelete,:) = [];
    TrialInfo.TargetZoneType(todelete,:) = [];
    TrialInfo.TransferFunctionLeft(todelete,:) = [];
    TrialInfo.Reward(:,todelete) = [];
    TrialInfo.Success(todelete,:) = [];
    
    TrialInfo.StayTime(:,todelete) = [];
    TrialInfo.StayTimeStart(:,todelete) = [];
    TrialInfo.TrialID(:,todelete) = [];
    TrialInfo.Perturbation(todelete,:) = [];

end

end