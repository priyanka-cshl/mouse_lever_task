function [legend,param,not_ints] = GetSettings4Arduino(h)

not_ints = []; % convert to integers for Arduino communication purpose

legend(1) = {'which_odor'}; param(1) = h.current_trial_block.Data(4);
legend(2) = {'PGrey Sync'}; param(2) = h.trigger_ext_camera.Value;
legend(3:4) = {'DACgain' 'DACdc'};
param(3) = round(10000*h.DAC_settings.Data(1),4,'significant');
param(4) = h.DAC_settings.Data(2);
not_ints = [not_ints 4];
legend(5) = {'RewardHold-I'}; param(5) = h.current_trial_block.Data(5);
legend(6) = {'RewardHold-II'}; param(6) = h.MultiRewards.Value*h.RewardControls.Data(4);
legend(7) = {'SummedHold'}; 
% if (h.which_perturbation.Value >= 4 && h.current_trial_block.Data(3) == 1)
%     param(7) = h.TrialSettings.Data(5); % hack - if perturbation trial - the summed hold is not valid
% else
param(7) = h.TargetHold.Data(3)*h.summedholdfactor.Data(1);
% end        
legend(8) = {'RewardDuration-I'}; param(8) = h.RewardControls.Data(1);
legend(9) = {'RewardDuration-II'}; param(9) = h.MultiRewards.Value*h.RewardControls.Data(2);
legend(10:11) = {'TriggerON' 'TriggerOFF'}; param(10:11) = h.TrialSettings.Data(1:2);
not_ints = [not_ints 10:11];
legend(12:14) = {'TriggerHOLD' 'MinTrialLength' 'MaxTrialLength'};
param(12:14) = [h.current_trial_block.Data(6); h.TrialSettings.Data(4:5)];
legend(15) = {'IRI'}; param(15) = h.MultiRewards.Value*h.RewardControls.Data(3);
legend(16) = {'PostRewardbuffer'}; param(16) = h.RewardControls.Data(5);

legend(17:19) = {'HighLim' 'Target' 'LowLim'};
param(17:19) = h.TargetDefinition.Data;
not_ints = [not_ints 17:19]; % convert to integers for Arduino communication purpose
legend(20) = {'TFsize'}; param(20) = h.TransferFunction.Data(1);

legend(21) = {'HalfZoneSize'}; param(21) = h.locations_per_zone.Data(1);
legend(22) = {'MotorZero'}; param(22) = h.MotorLocationArduinoMax + 1;

legend(23) = {'offtarget_locations'}; param(23) = h.locations_per_zone.Data(3); 

legend(24) = {'LongITI'}; param(24) = h.TrialSettings.Data(end);
% Perturbations
legend(25) = {'PerturbationType'};
if h.which_perturbation.Value > 0 && h.current_trial_block.Data(3) == 1
    if h.which_perturbation.Value == 7
        param(25) = h.which_perturbation.Value - 1;
    else
        param(25) = h.which_perturbation.Value;
    end
else
    param(25) = 0;
end
legend(26) = {'PerturbationValue'};
if h.current_trial_block.Data(3) == 1
    switch h.which_perturbation.Value
        case 4
            param(26) = 1;
        case {5,6,7}
            param(26) = h.PerturbationSettings.Data(3) + h.MotorLocationArduinoMax + 1;
        case 8
            param(26) = ceil(h.TFgain.Data(1));
        otherwise
    end
else
    param(26) = 0;
end
legend(27:29) = {'FakeHighLim' 'FakeTarget' 'FakeLowLim'};
if h.which_perturbation.Value == 2 && h.current_trial_block.Data(3) == 1
    param(27:29) = h.fake_target_zone.Data(1:3);
    not_ints = [not_ints 27:29]; % convert to integers for Arduino communication purpose
else
    param(27:29) = [0 0 0];
end

legend(30) = {'FeedbackDelay'}; param(30) = 0;
legend(31) = {'Stage'}; param(31) = h.which_stage.Value;
% 32 and 33 are for sending numbers back from Arduino
legend(34:35) = {'SampleRate' 'RefreshRate'}; param(34:35) = h.DAQrates.Data;
end