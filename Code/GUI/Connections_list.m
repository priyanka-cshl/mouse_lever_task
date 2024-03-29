function [channel_names] = Connections_list()
% list of channel names assigned to the analog lines on the NI card
% ordered 0,1,2,.. where number corresponds to ai0, ai1, ai2, .....
channel_names = {...
    'lever_DAC',...
    'lever_raw',...
    'stimulus_location',...
    'stimulus_location_scaled',...
    'thermistor',...
    'lickpiezo',...
    'trial_on',...
    'in_target_zone',...
    'in_reward_zone',...
    'rewards',...
    'licks',...
    'homesensor',...
    'camerasync',...
    };
end