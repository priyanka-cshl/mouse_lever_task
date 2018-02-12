function [h] = SetUpOpenLoopTrials(h)

% motor locations to use
all_locations = [-h.SessionSettings.Data(2):h.SessionSettings.Data(3):h.SessionSettings.Data(2)];
all_odors = h.Odor_list.Value
num_repeats = h.SessionSettings.Data(1);

Trial_list = [repmat(all_locations',numel(all_odors),1) ...
    reshape(repmat(all_odors,numel(all_locations),1), numel(all_locations)*numel(all_odors),1)];

AllTrials = [];
for i = 1:num_repeats
    AllTrials = [AllTrials; Trial_list(randperm(size(Trial_list,1)),:)];
end

h.TrialSequence = AllTrials;
