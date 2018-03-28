function [Odors, ZonesToUse, Lever_mat, Motor_mat] = TruncateTrials(Lever, Motor,TrialInfo, Zones, Params)
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
timepoints_all = cellfun(@numel, Lever);
timepoints_max = max(timepoints_all);

% reformat 'Lever' cell array to a matrix, pad short trials with NaNs
% for successes, only use time-points until reward delivery - NaNs after

for i = 1:size(Lever,2)
    timepoints_to_keep = timepoints_all(i); % length of the trial
    if TrialInfo.Success(i) % successful trial
        % truncate trial at time of reward delivery
        timepoints_to_keep = TrialInfo.Reward{i}(1);
    end
    Lever_mat(i,1:timepoints_to_keep) = Lever{i}(1:timepoints_to_keep);
    Motor_mat(i,1:timepoints_to_keep) = Motor{i}(1:timepoints_to_keep);
    timepoints_to_keep = timepoints_to_keep + 1;
    if timepoints_to_keep<=timepoints_max
        Lever_mat(i,timepoints_to_keep:timepoints_max) = NaN;
        Motor_mat(i,timepoints_to_keep:timepoints_max) = NaN;
    end
end

%% Align all trajectories to the time-point when they start moving the lever
% ie. lever voltage goes below thershold for Trigger ON = ~4.8V
LeverReAligned = []; idx = [];
for i = 1:size(Lever_mat,1) % each trial
    temp_lever = Lever_mat(i,:);
    temp_motor = Motor_mat(i,:);
    t = find(temp_lever<4.75, 1);
    if ~isempty(t)
        temp_lever = [temp_lever(t:end) NaN*ones(1,t-1)];
        temp_motor = [temp_motor(t:end) NaN*ones(1,t-1)];
        LeverReAligned = [LeverReAligned; temp_lever];
        MotorReAligned = [MotorReAligned; temp_motor];
        idx = [idx; i];
    end
end

%% find time-point at which location offset perturbation started

end
