function [h] = SetUpSequenceTrials(h)

h.SessionSettings.Data(1) = 300; % repeats
num_repeats = h.SessionSettings.Data(1);
% trials/repeat
h.current_trial_block.Data(3) = 1;

AllTrials = repmat([0 1],num_repeats,1);

% replacement trials - every 1 in 10 trials (only trials 6-10)
for i = 55:10:145
    foo = randperm(5);
    AllTrials(i+foo(1),2) = 2;
end

% omission trials - every 1 in 10 trials (only trials 6-10)
for i = 205:10:295
    foo = randperm(5);
    AllTrials(i+foo(1),2) = 0;
end

h.current_trial_block.Data(1) = size(AllTrials,1);
h.TrialSequence = AllTrials;
%guidata(h.hObject,h);


