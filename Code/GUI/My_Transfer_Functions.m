function [h] = My_Transfer_Functions(h)
%% find all three TFs
DAC_limits = h.DAC_levels.Data;
Zone_limits = h.locations_per_zone.Data;
my_target_levels = sort(h.target_level_array.Data);
% compute new target definition
for i = 1:length(my_target_levels)
    target = my_target_levels(i);
    uplim = target + h.ZoneLimitSettings.Data(1)+...
        target*h.ZoneLimitSettings.Data(2);
    lowlim = target - h.ZoneLimitSettings.Data(1)-...
        target*h.ZoneLimitSettings.Data(2);
    
    target_limits(i,:) = [h.TrialSettings.Data(2) lowlim target uplim h.TrialSettings.Data(1)];
    [TF] = LeverTransferFunction_discrete(target_limits(i,:), DAC_limits, Zone_limits,...
        h.TransferFunction.Data(1));
    h.(['TF',num2str(i)]) = TF;
end
