function [Odors, ZonesToUse, TracesTruncated, MotorTruncated] = TruncateAlignOpenLoopTrials(Traces, Motor, TrialInfo)
clear TracesTruncated;
clear MotorTruncated;

% get rid of zones with less than 5 trials
ZonesToUse = unique(TrialInfo.TargetZoneType);
todelete = [];
for i = 1:numel(ZonesToUse)
    if numel(find(TrialInfo.TargetZoneType==ZonesToUse(i)))<5
        todelete = [todelete; i];
    end
end
ZonesToUse(todelete,:) = []; 

Odors = unique(TrialInfo.Odor);

% find the length of the longest trial
timepoints_all = cellfun(@numel, Traces);
timepoints_max = max(timepoints_all);

% reformat 'Lever' cell array to a matrix, pad short trials with NaNs
% for successes, only use time-points until reward delivery - NaNs after

for i = 1:size(Traces,2)
    timepoints_to_keep = timepoints_all(i); % length of the trial
    TracesTruncated(i,1:timepoints_to_keep) = Traces{i}(1:timepoints_to_keep);
    MotorTruncated(i,1:timepoints_to_keep) = Motor{i}(1:timepoints_to_keep);
    timepoints_to_keep = timepoints_to_keep + 1;
    if timepoints_to_keep<=timepoints_max
        TracesTruncated(i,timepoints_to_keep:timepoints_max) = NaN;
        MotorTruncated(i,timepoints_to_keep:timepoints_max) = NaN;
    end
end

end
