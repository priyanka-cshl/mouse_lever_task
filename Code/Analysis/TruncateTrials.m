function [Odors, ZonesToUse, Truncated] = TruncateTrials(Traces, TrialInfo, Zones)
clear Lever_mat;
clear Motor_mat;

% get rid of zones with less than 5 trials
ZonesToUse = 1:size(Zones,1)';

% get rid of zones with spurious zones
% delete zones with fishy trials
f = find((Zones(:,1)==3)|(Zones(:,4)<5));
ZonesToUse(:,f) = [];

Odors = unique(TrialInfo.Odor);

% find the length of the longest trial
timepoints_all = cellfun(@numel, Traces.Lever);
timepoints_max = max(timepoints_all);

% reformat 'Lever' cell array to a matrix, pad short trials with NaNs
% for successes, only use time-points until reward delivery - NaNs after

for i = 1:size(Traces.Lever,2)
    timepoints_to_keep = timepoints_all(i); % length of the trial
    if TrialInfo.Success(i) % successful trial
        % truncate trial at time of reward delivery
        timepoints_to_keep = TrialInfo.Reward{i}(1);
    end
    
    TraceTypes = fieldnames(Traces);
    for j = 1:size(TraceTypes,1)        
        Truncated.([char(TraceTypes(j))])(i,1:timepoints_to_keep) = ...
            Traces.([char(TraceTypes(j))]){i}(1:timepoints_to_keep);
        %timepoints_to_keep = timepoints_to_keep + 1;
        if (timepoints_to_keep+1)<=timepoints_max
            Truncated.([char(TraceTypes(j))])(i,(timepoints_to_keep+1):timepoints_max) = NaN;
        end
    end
end

end
