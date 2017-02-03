function UpdateTrial_Callback(h)
% this function updates anything changes on a trial-by-trial basis
% or block-by-block basis

% is it a block update (TF and odor both change)
% OR
% is it a trial update (only odor change)
update_block = 0;
if mod(h.current_trial_block.Data(2),h.TransferFunction.Data(2)) == 0
    update_block = 1;
end

%% Step 1: update Odors
% shuffle odor list
odor_list = randperm(length(h.Odor_list.Value));
h.current_trial_block.Data(4) = h.Odor_list.Value(odor_list(1));
odor_states = [0 0 0];
odor_states(odor_list(1)) = 1;
% set all odor valves
outputSingleScan(h.Odors,odor_states);

%% Step 2: compute and update new TF
if update_block
    display('New Block');

    % note the old settings incase the update fails
    current_target = h.TargetDefinition.Data(2);
    current_target_level = [h.TargetLevel1.Value; h.TargetLevel2.Value; h.TargetLevel3.Value];

    %% shuffle arrays of targets after all targets have been uused
    block_num = h.current_trial_block.Data(1);
    block_num = block_num + 1;
    if mod(block_num,length(h.target_level_array.Data)) == 0
        h.target_level_array.Data = h.target_level_array.Data(randperm(length(h.target_level_array.Data)) );
    end
    h.current_trial_block.Data(1) = block_num; % update 'block number'
    %h.RewardStatus.Data(2) = 0; % reset 'rewards given in block'

    %% update target level
    h.TargetDefinition.Data(2) = ...
        h.target_level_array.Data( 1 + mod(block_num-1,length(h.target_level_array.Data)) );
    % Update current target level radio button
    h.(['TargetLevel',num2str( 1 + mod(block_num-1,length(h.target_level_array.Data)) )]).Value = 1;

    %h.target_level_array.Data( 1 + mod(block_num-1,length(h.target_level_array.Data)) )

    %% switch target and distractor if needed
    if h.is_distractor_on.Value
        if mod(floor((block_num-1)/h.distractor_block_size.Data),2) ~= abs(h.stimulus_map - 1)
            h.stimulus_map.value = abs(h.stimulus_map - 1);
        end
    end

    %% invoke target definition callback (this automatically calls Update_Arduino)
    [h] = Compute_TargetDefinition(h);
    [status] = Update_TransferFunction_discrete(h);
    pause(0.1);
    
    if status == 0
        % TF failed to update
        % reset target definition to old settings
        h.TargetDefinition.Data(2) = current_target;
        [h] = Compute_TargetDefinition(h);
        h.TargetLevel1.Value = current_target_level(1);
        h.TargetLevel2.Value = current_target_level(2);
        h.TargetLevel3.Value = current_target_level(3);
    end
end

callUpdate = 0;
if ~update_block
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
                [h] = Compute_TargetDefinition(h);
                callUpdate = 1;
            end
        end
    end
end

% update params other than TF
if status || callUpdate
    Update_Params(h);
end

% update GUI
guidata(h.hObject, h);



