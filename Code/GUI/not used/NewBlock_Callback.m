function NewBlock_Callback(h)
% this function updates anything changes on a block-by-block basis
% called by NI_Callback when rewards_in_block == max_per_block

global IsRewardedTrial;

display('----------New Block------------------------------');

%% shuffle arrays of targets after all targets have been used
block_num = h.current_trial_block.Data(1);
block_num = block_num + 1;
if mod(block_num,length(h.target_level_array.Data)) == 0
    h.target_level_array.Data = h.target_level_array.Data(randperm(length(h.target_level_array.Data)) );
end
h.current_trial_block.Data(1) = block_num; % update 'block number'
%h.RewardStatus.Data(2) = 0; % reset 'rewards given in block'

for i = 1:size(h.ProgressReport.Data,2)
    h.ProgressReport.Data(3,i) = round(100*h.ProgressReport.Data(2,i)/h.ProgressReport.Data(1,i),0,'decimals');
end

%% update target level
NoAntiBias = 1;
% check if antibias needs to be implemented and if previous trial was a failure
if (sum([h.TargetLevel1AntiBias.Value,h.TargetLevel2AntiBias.Value,h.TargetLevel3AntiBias.Value])>0 && ~IsRewardedTrial)
    which_target = find(sort(h.target_level_array.Data,'descend')==h.TargetDefinition.Data(2));
    if h.(['TargetLevel',num2str(which_target),'AntiBias']).Value
        NoAntiBias = 0;
        disp('antibiasing');
        h.NewTargetDefinition.Data(2) = h.TargetDefinition.Data(2);
    end
end

if NoAntiBias
    h.NewTargetDefinition.Data(2) = ...
        h.target_level_array.Data( 1 + mod(block_num-1,length(h.target_level_array.Data)) );
    % Update current target level radio button
    % h.(['TargetLevel',num2str( 1 + mod(block_num-1,length(h.target_level_array.Data)) )]).Value = 1;
end

%% switch target and distractor if needed
if h.is_distractor_on.Value
    if mod(floor((block_num-1)/h.distractor_block_size.Data),2) ~= abs(h.stimulus_map - 1)
        h.stimulus_map.value = abs(h.stimulus_map - 1);
    end
end

%% invoke target definition callback (this automatically calls Update_Arduino)
guidata(h.hObject, h);
% display('params modified by new block call');
OdorLocator('ZoneLimitSettings_CellEditCallback',h.hObject,[],h);

