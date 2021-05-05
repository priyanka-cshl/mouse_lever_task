function [h] = SetUpSequenceTrials(h)

h.SessionSettings.Data(1) = 150; % repeats
num_repeats = h.SessionSettings.Data(1);

% trials/repeat
h.current_trial_block.Data(3) = 1;

AllTrials = repmat([0 1],num_repeats,1);
h.TrialSequence = AllTrials;
h.current_trial_block.Data(1) = size(AllTrials,1);
%guidata(h.hObject,h);
