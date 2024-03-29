function NewBlockTrial_Callback(h)
% combo of New block and New Trial

% home motor if needed
if h.motor_home.BackgroundColor(1) == 0.5
    h.Arduino.write(72,'uint16');
    %pause(5)
end

global IsRewardedTrial;
global TrialsToPerturb;

disp(['---------- New Trial (#', num2str(h.current_trial_block.Data(2)),') ----------']);

%% shuffle arrays of targets after all targets have been used
h.target_level_array.Data = h.target_level_array.Data(randperm(length(h.target_level_array.Data)) );
% invert TF if needed
h.current_trial_block.Data(1) = (rand(1)<h.TFLeftprobability.Data(1)); % 50% chance of inverting TF

% block_num = h.current_trial_block.Data(1);
% block_num = block_num + 1;
% h.current_trial_block.Data(1) = block_num; % update 'block number'

% update performance
for i = 1:size(h.ProgressReport.Data,1)
    h.ProgressReport.Data(i,3) = round(100*h.ProgressReport.Data(i,2)/h.ProgressReport.Data(i,1),0,'decimals');
    h.ProgressReportLeft.Data(i,3) = round(100*h.ProgressReportLeft.Data(i,2)/h.ProgressReportLeft.Data(i,1),0,'decimals');
    h.ProgressReportRight.Data(i,3) = round(100*h.ProgressReportRight.Data(i,2)/h.ProgressReportRight.Data(i,1),0,'decimals');
    h.ProgressReportPerturbed.Data(i,3) = round(100*h.ProgressReportPerturbed.Data(i,2)/h.ProgressReportPerturbed.Data(i,1),0,'decimals');
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
    if h.preloaded_sequence.Value
        foo = sort(h.target_level_array.Data);
        whichzone = 1 + mod(h.current_trial_block.Data(2)-1,numel(h.trialsequence));
        h.current_trial_block.Data(5) = h.holdtimes(whichzone);
        whichzone = h.trialsequence(whichzone);
        h.TargetDefinition.Data(2) = foo(whichzone);
    elseif ~h.PseudoRandomZones.Value
        %h.NewTargetDefinition.Data(2) = h.target_level_array.Data(1);
        h.TargetDefinition.Data(2) = h.target_level_array.Data(1);
        %h.target_level_array.Data( 1 + mod(block_num-1,length(h.target_level_array.Data)) );
        % Update current target level radio button
        % h.(['TargetLevel',num2str( 1 + mod(block_num-1,length(h.target_level_array.Data)) )]).Value = 1;
    else
        %unused_targets = h.target_level_array.Data(find(floor(h.target_level_array.Data)~=floor(h.TargetDefinition.Data(2))));
        unused_targets = h.target_level_array.Data(find(abs(h.target_level_array.Data-h.TargetDefinition.Data(2))>0.5));
        h.TargetDefinition.Data(2) = unused_targets(1);
    end
end

% %% switch target and distractor if needed
% if h.is_distractor_on.Value
%     if mod(floor((block_num-1)/h.distractor_block_size.Data),2) ~= abs(h.stimulus_map - 1)
%         h.stimulus_map.value = abs(h.stimulus_map - 1);
%     end
% end

%% update odor
% shuffle odor list
odor_list = randperm(length(h.Odor_list.Value));
h.current_trial_block.Data(4) = h.Odor_list.Value(odor_list(1));
% odor_states = [0 0 0 0];
% odor_states(odor_list(1)) = 1;
% % set all odor valves
% outputSingleScan(h.Odors,odor_states);

%% update target hold time
if ~h.preloaded_sequence.Value
    x = exprnd(h.TargetHold.Data(1));
    while (x + h.TargetHold.Data(2)) > h.TargetHold.Data(3)
        x = exprnd(h.TargetHold.Data(1));
    end
    h.current_trial_block.Data(5) = round(h.TargetHold.Data(2)+x,0);
end


%% update trigger hold time
x = exprnd(h.TriggerHold.Data(1));
while (x + h.TriggerHold.Data(2)) > h.TriggerHold.Data(3)
    x = exprnd(h.TriggerHold.Data(1));
end
h.TrialSettings.Data(3) = round(h.TriggerHold.Data(2)+x,0);


%% feedback perturbation settings
if (h.which_perturbation.Value>1)
    % shuffle perturbed trial vector if needed
    if ~mod(h.current_trial_block.Data(2),numel(TrialsToPerturb))
        TrialsToPerturb = TrialsToPerturb([randperm(floor(numel(TrialsToPerturb)/2)) ...
            floor(numel(TrialsToPerturb)/2)+(1:floor(numel(TrialsToPerturb)/2))]);
    end
    % bsed on the user set probability,
    % check if the trial is to be perturbed or not
    h.current_trial_block.Data(3) = TrialsToPerturb(mod(h.current_trial_block.Data(2),numel(TrialsToPerturb)) + 1);
    
    if h.current_trial_block.Data(3) && h.which_perturbation.Value>1
        switch h.which_perturbation.Value
            case 2 % decouple water and odor
                % select randomly a target level from a zone that's not of the target zone
%                 unused_targets = h.target_level_array.Data(find(floor(h.target_level_array.Data)~=...
%                     floor(h.TargetDefinition.Data(2))));
                unused_targets = h.target_level_array.Data(find(abs(h.target_level_array.Data-h.TargetDefinition.Data(2))>0.5));
                h.fake_target_zone.Data(2) = unused_targets(randi(length(unused_targets)));
                h.fake_target_zone.ForegroundColor = [0 0 0];
                
            case 3 % no odor
                h.current_trial_block.Data(4) = 4;
                
            case 4 % flip map
                h.current_trial_block.Data(5) = 2000; % increase hold time in this trial
                
            case 5 % location offset
                %h.current_trial_block.Data(5) = 100;
                %h.TargetDefinition.Data(2) = 2 + h.TargetDefinition.Data(2) - floor(h.TargetDefinition.Data(2)); % only z2 trials
                h.TargetDefinition.Data(2) = h.PerturbationSettings.Data(4);
                %if h.PerturbationSettings.Data(3)>0
                if rand(1)<0.5
                    h.PerturbationSettings.Data(3) = -abs(h.PerturbationSettings.Data(3));
                else
                    h.PerturbationSettings.Data(3) = abs(h.PerturbationSettings.Data(3));
                end
        end
    else
        h.fake_target_zone.ForegroundColor = [0.65 0.65 0.65];
    end
    
end

%% invoke target definition callback (this automatically calls Update_Params)
set(h.motor_home,'BackgroundColor',[0.94 0.94 0.94]);
guidata(h.hObject, h);
% display('params modified by new block call');
OdorLocator('ZoneLimitSettings_CellEditCallback',h.hObject,[],h);

