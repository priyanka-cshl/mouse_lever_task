function [legend,param,locs] = OpenLoop_Settings(h)

legend(1:8) = {'odorvial' 'motorlocation' 'motor_settle' 'pre-odor' 'odor' 'purge' 'post-odor' 'iti'};
param(1) = h.current_trial_block.Data(6);
if h.current_trial_block.Data(7) > 500 % 999 (passive replay) or 800 (pseudo random pulse train)
    param(2) = h.current_trial_block.Data(7);
else
    param(2) = h.current_trial_block.Data(7) + h.MotorLocationArduinoMax + 1; % get rid of negative values
end
param(3:8) = h.TrialSettings.Data(1:6);

legend(9:10) = {'DACgain' 'DACdc'};
param(9) = round(10000*h.DAC_settings.Data(1),4,'significant');
param(10) = h.DAC_settings.Data(2);

voltage_to_int = round(inv(h.DAC_levels.Data(2)/(2^16)));
param(10) = round(param(10)*voltage_to_int);
param(param>2^16-1) = 2^16-1;

legend(11) = {'water time'};
param(11) = h.reward_time.Data(1);

legend(12) = {'ITIAirState'};
param(12) = h.ITIAirState.Value;

locs = [];
if h.PseudoSequence.Value && h.current_trial_block.Data(2)
    locs = h.LocationSequence(h.current_trial_block.Data(2),:); % which locations
    locs = locs + + h.MotorLocationArduinoMax + 1; % get rid of negative values
end

end