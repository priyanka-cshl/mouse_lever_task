function [h] = Compute_TargetDefinition(h)
% readjust target zone upper and lower limits in proportion to the
% partitioning of the available lever range

total_range = h.TrialSettings.Data(1) - h.TrialSettings.Data(2); % in volts
% available lever space - upper and lower 'halves' - normalized
mywidth(1) = (h.TrialSettings.Data(1) - h.TargetDefinition.Data(2))/total_range;
mywidth(2) = 1 - mywidth(1);
% target zone widths (normalized) - - upper and lower 'halves'
mywidth = 2*mywidth*h.ZoneLimitSettings.Data(1);

% compute new target zone definition
h.TargetDefinition.Data(1) = h.TargetDefinition.Data(2) + mywidth(1);
h.TargetDefinition.Data(3) = h.TargetDefinition.Data(2) - mywidth(2);

h.fake_target_zone.Data(1) = h.fake_target_zone.Data(2) +  mywidth(1);
h.fake_target_zone.Data(3) = h.fake_target_zone.Data(2) -  mywidth(2);

% compute number of locations to be allocated to the target zone
h.locations_per_zone.Data(1) = round(h.MotorLocations * (h.ZoneLimitSettings.Data(1)*2)/total_range);
% zones outside the target zone
% note: h.locations_per_zone.Data(2) is always 0 - locations to be skipped
h.locations_per_zone.Data(3) = h.MotorLocations - sum(h.locations_per_zone.Data(1:2));

end