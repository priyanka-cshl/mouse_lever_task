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

if h.which_perturbation.Value == 11 && mod(floor(h.current_trial_block.Data(2)/h.PerturbationSettings.Data(2)),2)
    legend(21) = {'HalfZoneSize'}; param(21) = h.locations_per_zone.Data(1);
    if h.TFLeftprobability.Data(1)
        legend(22) = {'MotorZero'}; param(22) = h.MotorLocationArduinoMax + 1 + h.blockshiftfactor.Data(1)*h.locations_per_zone.Data(1);
    else
        legend(22) = {'MotorZero'}; param(22) = h.MotorLocationArduinoMax + 1 - h.blockshiftfactor.Data(1)*h.locations_per_zone.Data(1);
    end
else
    legend(21) = {'HalfZoneSize'}; param(21) = h.locations_per_zone.Data(1);
    legend(22) = {'MotorZero'}; param(22) = h.MotorLocationArduinoMax + 1;
end

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

% hack plot colors
% defaults
if h.VisualVersion.Value
    h.trial_on_1.FaceColor = [0.9900 0.9200 0.8000];
    h.trial_on_2.FaceColor = [0.9900 0.9200 0.8000];
    h.trial_on_3.FaceColor = [0.9900 0.9200 0.8000];
else
    h.trial_on_1.FaceColor = [0.8000 0.8000 0.8000];
    h.trial_on_2.FaceColor = [0.8941 0.9412 0.9020];
    h.trial_on_3.FaceColor = [0.8706 0.9216 0.9804];
end
h.trial_on_4.FaceColor = [0.9300 0.8400 0.8400];

legend(26) = {'PerturbationValue'};
if h.current_trial_block.Data(3) == 1
    switch h.which_perturbation.Value
        case 3 % no odor
            param(1) = 0;
        case 4
            param(26) = 1;
        case {5,6,7}
            param(26) = h.OffsetParams.Data(3) + h.MotorLocationArduinoMax + 1;
        case 8
            param(26) = ceil(h.TFgain.Data(1));
        case {9, 10}
            param(26) = h.FeedbackHaltParams.Data(1);
        case 12 % LED+air
            param(1) = 4;
            h.trial_on_4.FaceColor = [0.9300 0.8400 0.8400];
        case 13 % LED only
            param(1) = 5;
            h.trial_on_4.FaceColor = [0.9900 0.9200 0.8000];
        otherwise
    end
else
    param(26) = 0;
end

%% override odors for visual only trials
if h.current_trial_block.Data(3) == 0
        % only if they aren't already perturbation trials 
        % (except fake target zone type perturbation)
    if h.VisualAirTrials.Value
        param(1) = 4;
        h.current_trial_block.Data(3) = 2;
    elseif h.VisualVersion.Value
        param(1) = 5;
        h.current_trial_block.Data(3) = 2;
    end
    
elseif h.current_trial_block.Data(3) == 1 && h.which_perturbation.Value == 2
    
    if h.VisualAirTrials.Value
        param(1) = 4;
        %h.current_trial_block.Data(3) = 2;
    elseif h.VisualVersion.Value
        param(1) = 5;
        %h.current_trial_block.Data(3) = 2;
    end
end

legend(27:29) = {'FakeHighLim' 'FakeTarget' 'FakeLowLim'};
if h.which_perturbation.Value == 2 && h.current_trial_block.Data(3) == 1
    param(27:29) = h.fake_target_zone.Data(1:3);
    not_ints = [not_ints 27:29]; % convert to integers for Arduino communication purpose
elseif (h.which_perturbation.Value == 9) || (h.which_perturbation.Value == 10) && h.current_trial_block.Data(3) == 1
    param(28) = h.FeedbackHaltParams.Data(2);
    not_ints = [not_ints 28];
    if h.which_perturbation.Value == 10
        if h.TFLeftprobability.Data == 0
            param(27) = h.FeedbackHaltParams.Data(3);
        else
            param(27) = -h.FeedbackHaltParams.Data(3);
        end
        param(27) = param(27) + h.MotorLocationArduinoMax + 1;
    end
    param(29) = 0;
else
    param(27:29) = [0 0 0];
end

legend(30) = {'FeedbackDelay'}; param(30) = 0;

%legend(31) = {'Stage'}; param(31) = h.which_stage.Value;
legend(31) = {'OpenLoop'}; param(31) = h.OpenLoopSettings.Value - 1;
if h.OpenLoopSettings.Value>3 
    if strcmp(h.ReplayState.String,'Close loop')
        param(31) = 1;
    else
        param(31) = h.OpenLoopSettings.Value - 3 + 10;
    end
end

% 32 and 33 are for sending numbers back from Arduino
legend(34:35) = {'SampleRate' 'RefreshRate'}; param(34:35) = h.DAQrates.Data;
end