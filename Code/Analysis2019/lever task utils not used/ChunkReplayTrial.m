% organize the session data into a cell array of trials
function [Replay] = ChunkReplayTrial(TTLs, Replay, TrialInfo)

global SampleRate; % = 500; % samples/second
global startoffset; % = 1; % seconds

% loop through all replay trials
for thisBlock = 1:numel(Replay.ReplayTrialIDs)
    for thisReplay = 1:numel(Replay.ReplayTrialIDs{thisBlock})
        % get trial ID
        trialIdx = Replay.ReplayTrialIDs{thisBlock}(thisReplay);
        % find Trial timestamps for this trial in the oeps file
        TS = TTLs.Trial(trialIdx,:);
        % find all odor valve transitions within this replay
        ValveEvents = [];
        for thisOdor = 1:3
            myEvents = intersect(find(TTLs.(['Odor',num2str(thisOdor)])(:,1)>=TS(1,1)),...
                          find(TTLs.(['Odor',num2str(thisOdor)])(:,1)<TS(1,2)));
            myTimeStamps = TTLs.(['Odor',num2str(thisOdor)])(myEvents,:);
            ValveEvents = vertcat(ValveEvents,...
                                [myTimeStamps thisOdor*ones(numel(myEvents),1)]);
        end
        % Resort ValveEvents by occurence order 
        [~,I] = sort(ValveEvents(:,1));
        ValveEvents = ValveEvents(I,:);
        
        for thisTrial = 1:numel(Replay.CloseLoopTrialIDs{thisBlock})
            trialIdx = Replay.CloseLoopTrialIDs{thisBlock}(thisTrial);
            PreOdorSamples = floor(TrialInfo.OdorStart(trialIdx,1)*SampleRate);
            PostOdorSamples
            traceLength = numel(find(Replay.CloseLoopTraces{thisBlock}(:,1)==thisTrial));
            odorStart
        end
    end
end

end