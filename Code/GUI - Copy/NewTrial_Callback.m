function NewTrial_Callback(h)
% this function updates anything changes on a trial-by-trial basis
% called by NI_Callback when a trial ends

callUpdate = 0; % whether to update Arduino or not?

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
        Update_Arduino(h);
    end
end


