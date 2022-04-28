function [Odors, ZonesToUse, LeverReAligned, MotorReAligned, PIDReAligned, TrialInfo] = TruncateAlignTrials(Lever, Motor,TrialInfo, Zones, PID)
clear LeverTruncated;
clear MotorTruncated;
clear PIDTruncated;

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
%     if TrialInfo.Success(i) % successful trial
%         % truncate trial at time of reward delivery
%         timepoints_to_keep = TrialInfo.Reward{i}(1);
%     end
    LeverTruncated(i,1:timepoints_to_keep) = Lever{i}(1:timepoints_to_keep);
    MotorTruncated(i,1:timepoints_to_keep) = Motor{i}(1:timepoints_to_keep);
    PIDTruncated(i,1:timepoints_to_keep) = PID{i}(1:timepoints_to_keep);
    timepoints_to_keep = timepoints_to_keep + 1;
    if timepoints_to_keep<=timepoints_max
        LeverTruncated(i,timepoints_to_keep:timepoints_max) = NaN;
        MotorTruncated(i,timepoints_to_keep:timepoints_max) = NaN;
        PIDTruncated(i,timepoints_to_keep:timepoints_max) = NaN;
    end
end

%% Align all trajectories to the time-point when they start moving the lever
% ie. lever voltage goes below thershold for Trigger ON = ~4.8V
LeverReAligned = []; MotorReAligned = []; PIDReAligned = []; idx = []; 
for i = 1:size(LeverTruncated,1) % each trial
    temp_lever = LeverTruncated(i,:);
    temp_motor = MotorTruncated(i,:);
    temp_pid = PIDTruncated(i,:);
    t = find(temp_lever<4.75, 1);
    if ~isempty(t)
        temp_lever = [temp_lever(t:end) NaN*ones(1,t-1)];
        temp_motor = [temp_motor(t:end) NaN*ones(1,t-1)];
        temp_pid = [temp_pid(t:end) NaN*ones(1,t-1)];
        LeverReAligned = [LeverReAligned; temp_lever];
        MotorReAligned = [MotorReAligned; temp_motor];
        PIDReAligned = [PIDReAligned; temp_pid];
        idx = [idx; i];
        TrialInfo.StayTimeStart{i} = TrialInfo.StayTimeStart{i} - t - 1;
    end
end
end
