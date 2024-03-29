function NextTrial_Callback(h)
% combo of New block and New Trial

% home motor if needed
if h.motor_home.BackgroundColor(1) == 0.5
    h.Arduino.write(72,'uint16');
    %pause(5)
end

global IsRewardedTrial;

display('----------New Trial------------------------------');

%% shuffle arrays of targets after all targets have been used
h.target_level_array.Data = h.target_level_array.Data(randperm(length(h.target_level_array.Data)) );

% invert TF if needed
h.current_trial_block.Data(1) = (rand(1)<h.TFLeftprobability.Data(1)); % 50% chance of inverting TF

% block_num = h.current_trial_block.Data(1);
% block_num = block_num + 1;
% h.current_trial_block.Data(1) = block_num; % update 'block number'

for i = 1:size(h.ProgressReport.Data,1)
    h.ProgressReport.Data(i,3) = round(100*h.ProgressReport.Data(i,2)/h.ProgressReport.Data(i,1),0,'decimals');
end

%% update target level
NoAntiBias = 1;
% check if antibias needs to be implemented and if previous trial was a failure
if (sum([h.TargetLevel1AntiBias.Value,h.TargetLevel2AntiBias.Value,h.TargetLevel3AntiBias.Value])>0 && ~IsRewardedTrial)
    %which_target = find(sort(h.target_level_array.Data,'descend')==h.TargetDefinition.Data(2));
    which_target = floor(h.TargetDefinition.Data(2));
    if h.(['TargetLevel',num2str(which_target),'AntiBias']).Value
        NoAntiBias = 0;
        disp('antibiasing');
        %h.NewTargetDefinition.Data(2) = h.TargetDefinition.Data(2);
        %h.NewTargetDefinition.Data(2) = floor(h.TargetDefinition.Data(2)) + ...
        h.TargetDefinition.Data(2) = floor(h.TargetDefinition.Data(2)) + ...
            h.target_level_array.Data(1) - floor(h.target_level_array.Data(1));
    end
end

if NoAntiBias
    %h.NewTargetDefinition.Data(2) = h.target_level_array.Data(1);
    h.TargetDefinition.Data(2) = h.target_level_array.Data(1);
        %h.target_level_array.Data( 1 + mod(block_num-1,length(h.target_level_array.Data)) );
    % Update current target level radio button
    % h.(['TargetLevel',num2str( 1 + mod(block_num-1,length(h.target_level_array.Data)) )]).Value = 1;
end

%% update odor
% shuffle odor list
odor_list = randperm(length(h.Odor_list.Value));
h.current_trial_block.Data(4) = h.Odor_list.Value(odor_list(1));
% odor_states = [0 0 0 0];
% odor_states(odor_list(1)) = 1;
% % set all odor valves
% outputSingleScan(h.Odors,odor_states);

%% update target hold time
x = exprnd(h.TargetHold.Data(1));
while (x + h.TargetHold.Data(2)) > h.TargetHold.Data(3)
    x = exprnd(h.TargetHold.Data(1));
end
h.current_trial_block.Data(5) = round(h.TargetHold.Data(2)+x,0);

%% feedback perturbation settings
if (h.which_perturbation.Value)
    % bsed on the user set probability,
    % check if the trial is to be perturbed or not
    perturb = (rand(1) <= h.PerturbationSettings.Data(1));
    if (perturb ~= h.current_trial_block.Data(3))
        h.current_trial_block.Data(3) = perturb;
    end
    if perturb && (h.which_perturbation.Value == 2) % decouple feedback
        % select randomly a target level that is not currently in use
        %unused_targets = setdiff(h.target_level_array.Data,h.NewTargetDefinition.Data(2));
        unused_targets = setdiff(h.target_level_array.Data,h.TargetDefinition.Data(2));
        new_fake_target = unused_targets(randi(length(unused_targets)));
        if  h.PerturbationSettings.Data(3) ~= new_fake_target % fake target has changed
            h.PerturbationSettings.Data(3) = new_fake_target;
        end
        %h.current_trial_block.Data(5) = h.TargetHold.Data(3);
    end      
end

%% invoke target definition callback (this automatically calls Update_Params)
set(h.motor_home,'BackgroundColor',[0.94 0.94 0.94]);
guidata(h.hObject, h);
% display('params modified by new block call');
OdorLocator('ZoneLimitSettings_CellEditCallback',h.hObject,[],h);

