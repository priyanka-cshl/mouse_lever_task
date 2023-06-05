function [h] = SetUpOpenLoopTrials(h)

% motor locations to use
if h.SessionSettings.Data(3)
    all_locations = -h.SessionSettings.Data(2):h.SessionSettings.Data(3):h.SessionSettings.Data(2);
else
    all_locations = h.SessionSettings.Data(2); % only one location;
end
all_odors = h.Odor_list.Value;
num_repeats = h.SessionSettings.Data(1);

% trials/repeat
h.current_trial_block.Data(3) = numel(all_locations)*numel(all_odors);

% make a list of trials 
if ~h.PseudoSequence.Value % single pulses
    Trial_list = [repmat(all_locations',numel(all_odors),1) ...
        reshape(repmat(all_odors,numel(all_locations),1), numel(all_locations)*numel(all_odors),1)];
else % Pseudorandom location sequence
    Trial_list = [800*ones(numel(all_odors),1) all_odors'];
end

% append a passive replay trial
if h.PassiveReplay.Value
    Trial_list(end+1,:) = [999 0];
    h.current_trial_block.Data(3) = h.current_trial_block.Data(3) + 1;
end

if h.HaltReplay.Value && h.NumTemplates.Data(1)>0
    replaysperrep = ceil(h.NumTemplates.Data(1)/num_repeats);
    for i = 1:replaysperrep
        Trial_list(end+1,:) = [999 0];
        h.current_trial_block.Data(3) = h.current_trial_block.Data(3) + 1;
    end
end
    
AllTrials = [];
for i = 1:num_repeats
    AllTrials = [AllTrials; Trial_list(randperm(size(Trial_list,1)),:)];
end

% first trial cannot be replay
if AllTrials(1,1) > 900
    foo = AllTrials(1,:);
    f = find(AllTrials(:,1)<900,1,'first');
    AllTrials(1,:) = AllTrials(f,:);
    AllTrials(f,:) = foo;
end

% if doing Halt replay 
if h.HaltReplay.Value
    % replace all but first replay index with 998 from 999
    f = find(AllTrials(:,1)==999);
    f(1) = [];
    AllTrials(f,1) = 998;
    % check there only as many replay trials as available
    extrareplays = numel(f) + 1 - h.NumTemplates.Data(1);
    f = find(AllTrials(:,1)==998,extrareplays,'last');
    AllTrials(f,:) = [];
end

LocationSequence = [];
if h.PseudoSequence.Value % pseudorandom sequence
    for i = 1:size(AllTrials,1)
        if AllTrials(i,1) == 800
            LocationSequence(i,:) = all_locations(randperm(numel(all_locations)));
        else
            LocationSequence(i,:) = 0*all_locations; % PG: 23/03/16
        end
    end
    h.current_trial_block.Data(3) = numel(all_odors);
end

h.TrialSequence = AllTrials;
h.LocationSequence = LocationSequence;
h.current_trial_block.Data(1) = size(AllTrials,1);
%guidata(h.hObject,h);
