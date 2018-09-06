function [legend,param] = OpenLoop_Settings(h)

legend(1:8) = {'odorvial' 'motorlocation' 'motor_settle' 'pre-odor' 'odor' 'purge' 'post-odor' 'iti'};
param(1) = h.current_trial_block.Data(6);
param(2) = h.current_trial_block.Data(7) + h.MotorLocationArduinoMax + 1; % get rid of negative values
param(3:8) = h.TrialSettings.Data(1:6);
end