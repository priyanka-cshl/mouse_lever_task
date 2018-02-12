function [legend,param] = OpenLoop_Settings(h)

legend(1:7) = {'motor_settle' 'pre-odor' 'odor' 'post-odor' 'iti' 'odorvial' 'motorlocation'};
param(1:5) = h.TrialSettings.Data(1:5);
param(6) = h.current_trial_block.Data(6);
param(7) = h.current_trial_block.Data(7) + h.MotorLocations + 1; % get rid of negative values
end