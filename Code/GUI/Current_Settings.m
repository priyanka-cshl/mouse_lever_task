function [legend,param,not_ints] = Current_Settings(h,caller)

newlegends = 0;
if caller == 2
    newlegends = 1;
    caller = 1;
end
    
not_ints = [];
switch caller
    case 0 % settings that don't update within a session
        legend(1:2) = {'SampleRate' 'RefreshRate'};
        param(1:2) = h.DAQrates.Data;
        
        legend(3:4) = {'DACgain' 'DACdc'};
        param(3) = round(10000*h.DAC_settings.Data(1),4,'significant');
        param(4) = h.DAC_settings.Data(2);
        % convert to integers for Arduino communication purpose
        not_ints = [not_ints 4];
        
        legend(5:6) = {'RewardHoldTime' 'RewardDuration'};
        param(5) = h.current_trial_block.Data(5);
        param(6) = h.RewardControls.Data;
        
        legend(7) = {'MaxPerBlock'};
        param(7) = h.TransferFunction.Data(2);
        
        legend(8) = {'PerturbationProbability'};
        param(8) = h.PertubationSettings.Data(1);
        
        legend(9:10) = {'TriggerON' 'TriggerOFF'};
        param(9:10) = h.TrialSettings.Data(1:2);
        % convert to integers for Arduino communication purpose
        not_ints = [not_ints 9:10];
        
        legend(11:14) = {'TriggerHOLD' 'TriggerSmooth' 'MinTrialLength' 'MaxTrialLength'};
        param(11:14) = h.TrialSettings.Data(3:6);
        
    case 1 % settings that update within a session
        legend(1) = {'Timestamp'};
        param(1) = h.timestamp.Data;
        
        legend(2) = {'WhichTarget'};
        param(2) = h.stimulus_map.Value;
        
        legend(3:5) = {'HighLim' 'Target' 'LowLim'};
        param(3:5) = h.NewTargetDefinition.Data;
        % convert to integers for Arduino communication purpose
        not_ints = [not_ints 3:5];
        
%         legend(6) = {'Stage'};
%         param(6) = h.which_stage.Value;
%         
%         legend(7:8) = {'TF_locations' 'TF_steepness'};
%         param(7:8) = h.TransferFunction.Data(1:NaN);
%         not_ints = [not_ints 8];

        legend(6:8) = {'target_locations' 'skip_locations' 'offtarget_locations'};
        param(6:8) = h.locations_per_zone.Data(1:3);
        
        legend(9) = {'StimulusDelay'};
        if (h.is_stimulus_on.Value)
            if h.current_trial_block.Data(3) == 1 && h.which_perturbation.Value == 2
                param(9) = 1 + 1000*h.PertubationSettings.Data(2);
                %param(9) = 1 + h.PertubationSettings.Data(2);
            else
                param(9) = 1;
            end
        else
            param(9) = 0;
        end
        
        legend(10) = {'DistractorDelay'};
        if (h.is_distractor_on.Value)
            param(10) = 1 + h.delay_distractor_by.Data;
        else
            param(10) = 0;
        end
        
        legend(11:13) = {'FakeHighLim' 'FakeTarget' 'FakeLowLim'};
        if h.which_perturbation.Value == 3
            param(11:13) = h.PertubationSettings.Data(3:5);
        else
            param(11:13) = [0 0 0];
        end
        % convert to integers for Arduino communication purpose
        %not_ints = [not_ints 3:5];
        
        legend(14) = {'TFsize'};
        param(14) = h.TransferFunction.Data(1);
        
        legend(15) = {'Stage'};
        param(15) = h.which_stage.Value;
        
        legend(16) = {'signal_generator'};
        param(16) = h.fake_lever_signal.Value;
end

if newlegends
    legend(16:31) = legend(1:16);
    legend(1) = {'Timestamp'};
    legend(2:3) = {'MinWidth' 'PropWidth'};        
    legend(4:5) = {'DACgain' 'DACdc'};
    legend(6:7) = {'RewardHoldTime' 'RewardDuration'};
    legend(8) = {'MaxPerBlock'};
    legend(9) = {'PerturbationProbability'};
    legend(10:11) = {'TriggerON' 'TriggerOFF'};
    legend(12:15) = {'TriggerHOLD' 'StayMean' 'StayMin' 'StayMax'};
end
end