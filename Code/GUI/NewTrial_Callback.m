function NewTrial_Callback(h)
% this function updates anything changes on a trial-by-trial basis
% called by NI_Callback when a trial ends

callUpdate = 0; % whether to update Arduino or not?

%% update odor
% shuffle odor list
odor_list = randperm(length(h.Odor_list.Value));
h.current_trial_block.Data(4) = h.Odor_list.Value(odor_list(1));
odor_states = [0 0 0];
odor_states(odor_list(1)) = 1;
% set all odor valves
outputSingleScan(h.Odors,odor_states);

% update target hold time
x = exprnd(h.TargetHold.Data(1));
while (x + h.TargetHold.Data(2)) > h.TargetHold.Data(3)
    x = exprnd(h.TargetHold.Data(1));
end
h.current_trial_block.Data(5) = round(h.TargetHold.Data(2)+x,0);

%% feedback perturbation settings
if (h.which_perturbation.Value)
    % bsed on the user set probability,
    % check if the trial is to be perturbed or not
    perturb = (rand(1) <= h.PertubationSettings.Data(1));
    if (perturb ~= h.current_trial_block.Data(3))
        h.current_trial_block.Data(3) = perturb;
        callUpdate = 1;
    end
    if perturb && (h.which_perturbation.Value == 3) % decouple feedback
        % select randomly a target level that is not currently in use
        unused_targets = setdiff(h.target_levels_array.Data,h.TargetDefinition.Data(2));
        new_fake_target = unused_targets(randi(length(unused_targets)));
        if  h.PertubationSettings.Data(4) ~= new_fake_target % fake target has changed
            h.PertubationSettings.Data(4) = new_fake_target;
            callUpdate = 2;
        end
    end      
end

if callUpdate
    display('params modified by new trial call');
    if callUpdate == 2
        OdorLocator('ZoneLimitSettings_CellEditCallback',h.hObject,[],h);
    else
        Update_Params(h);
    end
end


