function [h] = Compute_TargetDefinition_fixspeed(h)

% readjust target zone upper and lower limits in proportion to the
% partitioning of the available lever range

mywidth(1) = h.ZoneLimitSettings.Data(1);
mywidth(2) = h.ZoneLimitSettings.Data(1);

h.TargetDefinition.Data(1) = h.TargetDefinition.Data(2) + mywidth(1);
h.TargetDefinition.Data(3) = h.TargetDefinition.Data(2) - mywidth(2);

h.fake_target_zone.Data(1) = h.fake_target_zone.Data(2) + mywidth(1);
h.fake_target_zone.Data(3) = h.fake_target_zone.Data(2) - mywidth(2);

% update target locations
h.locations_per_zone.Data(1) = floor(h.ZoneLimitSettings.Data(1)/...
    ((h.TrialSettings.Data(1) - h.minimumtarget)/(h.MotorLocationsRange + 0.5)));
        
end