function [Odors, ZonesToUse, Lever_mat] = SortTrialsByType(Lever, TrialInfo, Zones)
clear Lever_mat;

% get rid of zones with less than 5 trials
ZonesToUse = [];
for i = 1:size(Zones,1)
    if Zones(i,3)>5
        ZonesToUse = [ZonesToUse; i];
    end
end

Odors = unique(TrialInfo.Odor);

% find the length of the longest trial
timepoints_all = cellfun(@numel, Lever);
timepoints_max = max(timepoints_all);

% reformat 'Lever' cell array to a matrix, pad short trials with NaNs
% for successes, only use time-points until reward delivery - NaNs after

for i = 1:size(Lever,2)
    timepoints_to_keep = timepoints_all(i); % length of the trial
    if TrialInfo.Success(i) % successful trial
        % truncate trial at time of reward delivery
        timepoints_to_keep = TrialInfo.Reward{i};
    end
    Lever_mat(i,1:timepoints_to_keep) = Lever{i}(1:timepoints_to_keep);
    timepoints_to_keep = timepoints_to_keep + 1;
    if timepoints_to_keep<=timepoints_max
        Lever_mat(i,timepoints_to_keep:timepoints_max) = NaN;
    end
end

end
