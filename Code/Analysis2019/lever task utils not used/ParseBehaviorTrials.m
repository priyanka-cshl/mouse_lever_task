% organize the session data into a cell array of trials
function [Traces, TrialInfo, TargetZones] = ...
    ParseBehaviorTrials(MyData, MySettings, DataTags, Trial, sessionstart, sessionstop)

%% Parse inputs
if nargin < 4
    sessionstart = 0;
    sessionstop = max(MyData(:,1));
end

%% globals
global SampleRate; % = 500; % samples/second
global startoffset; % = 1; % seconds

%% get list of target zones used
TargetZones = unique(MySettings(:,18:20),'rows');
% bug handler - ignore spurious target zones
if size(TargetZones,1)>12
    disp('WARNING: session contains more than 12 target zones');
    TargetZonesTemp = TargetZones;
    f = find(round(TargetZones(:,1) - TargetZones(:,3))~=1);
    TargetZones(f,:) = [];
end

%% get list of fake target zones used
FakeTargetZones = unique(MySettings(:,26:28),'rows');
% bug handler - ignore spurious fake target zones
foo = FakeTargetZones;
foo(:,2) = foo(:,2) - foo(:,1);
if ~isempty(find((foo(:,2)==0)&(foo(:,1)<20)&(foo(:,1)>0)))
    disp('WARNING: session contains buggy fake zones');
    FakeTargetZones(find((foo(:,2)==0)&(foo(:,1)<20)&(foo(:,1)>0)),:) = [];
end

%% Get Column IDs
TrialCol = find(cellfun(@isempty,regexp(DataTags,'TrialON'))==0);
LeverCol = find(cellfun(@isempty,regexp(DataTags,'Lever'))==0);
MotorCol = find(cellfun(@isempty,regexp(DataTags,'Motor'))==0);
LickCol = find(cellfun(@isempty,regexp(DataTags,'Licks'))==0);
RewardCol = find(cellfun(@isempty,regexp(DataTags,'Rewards'))==0);
TZoneCol = find(cellfun(@isempty,regexp(DataTags,'InTargetZone'))==0);
RZoneCol = find(cellfun(@isempty,regexp(DataTags,'InRewardZone'))==0);
if ~isempty(find(cellfun(@isempty,regexp(DataTags,'thermistor'))==0))
    RespCol = find(cellfun(@isempty,regexp(DataTags,'thermistor'))==0);
else
    RespCol = find(cellfun(@isempty,regexp(DataTags,'respiration'))==0);
end
PerturbationCol(1) = find(cellfun(@isempty,regexp(DataTags,'WhichPerturbation'))==0);
PerturbationCol(2) = find(cellfun(@isempty,regexp(DataTags,'PerturbationValue'))==0);

%% Get Trial ON-OFF indices and timestamps
TrialOn  = Trial.Indices(:,1);
TrialOff = Trial.Indices(:,2);
TrialOffsets = Trial.Offsets(:,1); % correct for the trial offset (sample drops on digital channel)
OdorOffsets = Trial.Offsets(:,2);

%% Crunch data trial-by-trial
for thisTrial = 1:size(MySettings,1)
    % store original trial ID - some trials may get deleted later because of weird target zones
    TrialInfo.TrialID(thisTrial) = thisTrial;
    trialflag = 0; % pull down all flags - default it to use all trials
    thisTrialOffset = TrialOffsets(thisTrial); % this will be zero if there were no digital-analog sample drops
    
    if TrialOn(thisTrial) && ~isnan(thisTrialOffset)
        % extract continuous traces for lever, motor position, licks and sniffs
        % extract 1s before trial ON, and upto 1s before next trial start
        
        % correction factor
        TrialInfo.Offset(thisTrial) = thisTrialOffset;
        
        start_idx = TrialOn(thisTrial) - startoffset*SampleRate;
        start_idxCorrected = start_idx + thisTrialOffset;
        % exception handler for the first trial
        start_idx = max(1,start_idx);
        start_idxCorrected = max(1,start_idxCorrected);
        if thisTrial == 1 % all except first trial
            trialflag = -1; % ignore the very first trial
            LastTrialIdx = start_idx;
            LastTrialIdxCorrected = start_idx;
        end
        
        if thisTrial < length(TrialOn)
            stop_idx = TrialOn(thisTrial+1) - startoffset*SampleRate - 1; % until the next trial start
        else % last trial
            stop_idx = TrialOff(thisTrial) + startoffset*SampleRate;
            trialflag = -1; % ignore this trial
        end
        stop_idxCorrected = stop_idx + thisTrialOffset;
        % exception handler for the last trial
        stop_idx = min(stop_idx,size(MyData,1));
        stop_idxCorrected = min(stop_idxCorrected,size(MyData,1));
        
        %% Extract traces
        % Analog - use corrected indices - analog channnel dropped samples
        Traces.Timestamps.Analog(thisTrial) = { MyData(start_idxCorrected:stop_idxCorrected, 1) };
        Traces.Lever(thisTrial) = { MyData(start_idxCorrected:stop_idxCorrected, LeverCol) };
        Traces.Motor(thisTrial) = { MyData(start_idxCorrected:stop_idxCorrected, MotorCol) };
        Traces.Encoder(thisTrial) = { MyData(start_idxCorrected:stop_idxCorrected, EncoderCol) };
        Traces.Sniffs(thisTrial) = { MyData(start_idxCorrected:stop_idxCorrected, RespCol) };
        % Digital - use uncorrected indices
        Traces.Timestamps.Digital(thisTrial) = { MyData(start_idx:stop_idx, 1) };
        Traces.Licks(thisTrial) = { MyData(start_idx:stop_idx, LickCol) };
        Traces.Trial(thisTrial) = { MyData(start_idx:stop_idx, TrialCol) };
        Traces.Rewards(thisTrial) = { MyData(start_idx:stop_idx, RewardCol) };
        
        % start and stop indices of the extracted trace - w.r.t to the session
        TrialInfo.TraceIndices(thisTrial,:) = [start_idx stop_idx start_idxCorrected stop_idxCorrected];
        TrialInfo.TraceDuration(thisTrial,1) = (diff([start_idx stop_idx]) + 1)/SampleRate;
        
        %% Extract Trial Timestamps
        % w.r.t SessionStart (to go back to raw data if needed)
        thisTrialIdx = [TrialOn(thisTrial) TrialOff(thisTrial)]; %uncorrected
        thisTrialIdxCorrected = thisTrialIdx + thisTrialOffset;        
        TrialInfo.SessionIndices(thisTrial,:) = [thisTrialIdx thisTrialIdxCorrected]; % actual session indices - to go back to raw data
        TrialInfo.SessionTimestamps(thisTrial,:) = MyData([thisTrialIdx thisTrialIdxCorrected],1); % actual timestamps of trial start and end
        % w.r.t TrialStart
        TrialInfo.TimeIndices(thisTrial,:) = thisTrialIdx - start_idx;
        TrialInfo.Timestamps(thisTrial,:) = MyData(thisTrialIdx,1) - MyData(start_idx,1); % in seconds
        TrialInfo.Duration(thisTrial,1) = (diff(thisTrialIdx) + 1)/SampleRate; % in seconds
        % ignore trials that were outside the user-defined time period
        if (MyData(thisTrialIdx(1),1) < sessionstart) || (MyData(thisTrialIdx(1),1) > sessionstop)
            trialflag = -1;
        end
        TrialInfo.Valid(thisTrial,1) = trialflag;
        
        %% Which odor
        TrialInfo.Odor(thisTrial,1) = mode(MyData(thisTrialIdx(1):thisTrialIdx(2),TrialCol));
        
        % Odor ON timestamp (from the InRewardZone column - enocdes Odor ON before trialstart - see GUI)
        thisTrialInZone = find(diff(MyData(LastTrialIdx:thisTrialIdx(1), RZoneCol))==-1);
        if ~isempty(thisTrialInZone)
            TrialInfo.OdorStart(thisTrial,1) = thisTrialInZone(end) - thisTrialIdx(1); % odor start idx w.r.t trial start
        else
            TrialInfo.OdorStart(thisTrial,1) = NaN;
        end
        
        %% Timestamps for Odor ON and Trial ON - reconstructed from Lever trace
        TrialInfo.OdorStart(thisTrial,2) = OdorOffsets(thisTrial);
        %     % Odor ON timestamp
        %     LeverSnippet = MyData(LastTrialIdxCorrected:thisTrialIdxCorrected(1), LeverCol);
        %     LeverTemp = LeverSnippet;
        %     % assume a fix threshold of 4.8
        %     LeverTemp(LeverSnippet<=LeverThresh) = 0;
        %     LeverTemp(LeverTemp>0) = 1;
        %     % get all initiation hold periods
        %     Initiations = [find(diff([0; LeverTemp; 0])==1) find(diff([0; LeverTemp; 0])==-1)-1];
        %
        %     % Odor ON timestamp - find the first initiation period > trigger hold
        %     TriggerHold = MySettings(thisTrial,13); % in msec
        %     TriggerHold = floor(TriggerHold*SampleRate/1000); % in samples
        %     OdorStart = find(diff(Initiations,1,2)>=(TriggerHold-1),1,'last');
        %     while isempty(OdorStart)
        %         if size(Initiations,1) > 1
        %             % pool the last two
        %             Initiations(end-1,2) = Initiations(end,2);
        %             Initiations(end,:) = [];
        %             OdorStart = find(diff(Initiations,1,2)>=TriggerHold,1,'first');
        %         else
        %             disp(['Trial ',num2str(thisTrial),': No valid Initiations found!']);
        %             trialflag = -1;
        %             OdorStart = 1;
        %         end
        %     end
        % %     TrialInfo.OdorStart(thisTrial,2) = Initiations(OdorStart,1) + TriggerHold - 1 + LastTrialIdx - start_idx;
        %     TrialInfo.OdorStart(thisTrial,2) = Initiations(OdorStart,1) -1 + TriggerHold - numel(LeverSnippet);
        % convert both to seconds
        TrialInfo.OdorStart(thisTrial,:) = TrialInfo.OdorStart(thisTrial,:)/SampleRate;
        
        %% Which TargetZone
        if ~isempty(find(TargetZones(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1))
            TrialInfo.TargetZoneType(thisTrial,1) = ...
                find(TargetZones(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1);
        else
            % bug handler - for spurious target zones
            thiszonetarget = TargetZonesTemp(find(TargetZonesTemp(:,1) == mode(MyData(thisTrialIdx(1):thisTrialIdx(2),2)),1),2);
            TrialInfo.TargetZoneType(thisTrial,1) = find(TargetZones(:,2) == thiszonetarget);
        end
        
        %% TF : odor starts from left or right?
        % check the motor position at trialstart - 10 samples before trial start
        % to verify if the transfer function was inverted in this trial
        TrialInfo.TransferFunctionLeft(thisTrial,1) = (MyData(TrialOn(thisTrial)-1, MotorCol)>0);
        
        %% Reward timestamps
        thisTrialRewards = find(diff(MyData(start_idx:TrialOff(thisTrial)+10,RewardCol))==1); % indices w.r.t. to trace start
        thisTrialRewards = thisTrialRewards/SampleRate; % convert to seconds
        % force the reward time stamps that were before trial start to be -ve
        thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial,1)) = ...
            -1*thisTrialRewards(thisTrialRewards < TrialInfo.Timestamps(thisTrial,1));
        if ~isempty(thisTrialRewards)
            TrialInfo.Reward(thisTrial) = { thisTrialRewards };
            TrialInfo.Success(thisTrial,1) = any(thisTrialRewards>0); % successes and failures
        else
            TrialInfo.Reward(thisTrial) = { [] };
            TrialInfo.Success(thisTrial,1) = 0; % successes and failures
        end
        
        %% Calculate all stay times (in the target zone)
        thisTrialInZone = [find(diff([0;MyData(TrialOn(thisTrial):TrialOff(thisTrial), TZoneCol)])==1) ...
            find(diff([MyData(TrialOn(thisTrial):TrialOff(thisTrial), TZoneCol);0])==-1)]; % entry and exit indices w.r.t. Trial ON
        thisTrialInZone = TrialInfo.Timestamps(thisTrial,1) + thisTrialInZone/SampleRate; % convert to seconds and offset w.r.t. trace start
        if ~isempty(thisTrialInZone)
            TrialInfo.InZone(thisTrial) = { thisTrialInZone };
        else
            TrialInfo.InZone(thisTrial) = { [] };
        end
        
        %% Which Perturbation
        WhichPerturbation = mode( MyData(TrialOn(thisTrial):TrialOff(thisTrial), PerturbationCol(1)) );
        PerturbationValue = mode( MyData(TrialOn(thisTrial):TrialOff(thisTrial), PerturbationCol(2)) );
        
        if WhichPerturbation
            if WhichPerturbation < 100 % Fake target zone
                if isempty(find(TargetZones(:,2) == PerturbationValue))
                    TrialInfo.Perturbation(thisTrial,:) = [2 PerturbationValue];
                else
                    TrialInfo.Perturbation(thisTrial,:) = [2 find(TargetZones(:,2) == PerturbationValue)];
                end
            else
                TrialInfo.Perturbation(thisTrial,:) = [WhichPerturbation/100 0];
                switch WhichPerturbation
                    case 300 % No Odor
                    case 400 % flip map
                    case 500 % location offset I
                        TrialInfo.Perturbation(thisTrial,2) = PerturbationValue; % offset added
                    case {600, 700} % location offset II and III
                        TrialInfo.Perturbation(thisTrial,2) = PerturbationValue; % offset added
                        % get timestamps for offset start and feedback restart
                        % this is encoded in the InRewardZone Col - see GUI
                        if ~isempty(find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==1))
                            TrialInfo.PerturbationStart(thisTrial) = ...
                                find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==1);
                            TrialInfo.FeedbackStart(thisTrial) = ...
                                find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1,1,'last');
                            % convert to seconds w.r.t. trial start
                            TrialInfo.PerturbationStart(thisTrial) = TrialInfo.PerturbationStart(thisTrial)/SampleRate;
                            TrialInfo.FeedbackStart(thisTrial) = TrialInfo.FeedbackStart(thisTrial)/SampleRate;
                            % convert to seconds w.r.t. trace start
                            % (account for startoffset)
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
                        TrialInfo.Perturbation(thisTrial,2) = PerturbationValue; % new gain
                    case 900 % halts (older version - halt at trial start)
                        TrialInfo.Perturbation(thisTrial,2) = PerturbationValue; % halt duration?
                        if ~isempty(find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1))
                            TrialInfo.FeedbackStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1);
                            
                        end
                    case 1000 % halts (newer version - halt after lever crosses set threshold)
                        TrialInfo.Perturbation(thisTrial,2) = PerturbationValue; % halt duration?
                        if ~isempty(find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1))
                            TrialInfo.PerturbationStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==1);
                            TrialInfo.FeedbackStart(thisTrial) = find( diff([ MyData(TrialOn(thisTrial):TrialOff(thisTrial), RZoneCol); 0] )==-1);
                        end
                        
                    case 1100 % block shift perturbations
                        TrialInfo.Perturbation(thisTrial,2) = PerturbationValue; % shift amount?
                        
                end
            end
        else
            TrialInfo.Perturbation(thisTrial,:) = [0 0];
        end
    end
    
    LastTrialIdx = TrialOff(thisTrial); % current trial's end Idx
    LastTrialIdxCorrected = LastTrialIdx + thisTrialOffset; % current trial's end Idx
end



%% Extras: count trials of each target zone type
for i = 1:size(TargetZones,1)
    TargetZones(i,4) = numel( find(TrialInfo.TargetZoneType == i));
end

end