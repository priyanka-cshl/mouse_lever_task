function [h] = Compute_TargetDefinition_fixspeed(h)

% readjust target zone upper and lower limits in proportion to the
% partitioning of the available lever range
% total_range = h.TrialSettings.Data(1) - h.TrialSettings.Data(2);

%mywidth(1) = (h.TrialSettings.Data(1) - h.NewTargetDefinition.Data(2))/total_range;
%mywidth(2) = (h.NewTargetDefinition.Data(2) - h.TrialSettings.Data(2))/total_range;
% mywidth(1) = (h.TrialSettings.Data(1) - h.TargetDefinition.Data(2))/total_range;
% mywidth(2) = (h.TargetDefinition.Data(2) - h.TrialSettings.Data(2))/total_range;
% mywidth = 2*mywidth*h.ZoneLimitSettings.Data(1);

mywidth(1) = h.ZoneLimitSettings.Data(1);
mywidth(2) = h.ZoneLimitSettings.Data(1);
% compute new target zone definition
% h.NewTargetDefinition.Data(1) = h.NewTargetDefinition.Data(2) +...
%     mywidth(1);
% h.NewTargetDefinition.Data(3) = h.NewTargetDefinition.Data(2) -...
%     mywidth(2);

h.TargetDefinition.Data(1) = h.TargetDefinition.Data(2) +...
    mywidth(1);
h.TargetDefinition.Data(3) = h.TargetDefinition.Data(2) -...
    mywidth(2);

h.fake_target_zone.Data(1) = h.fake_target_zone.Data(2) + ...
    mywidth(1);
h.fake_target_zone.Data(3) = h.fake_target_zone.Data(2) - ...
    mywidth(2);

% h.PerturbationSettings.Data(3) = h.PerturbationSettings.Data(4) +...
%     mywidth(1);
% h.PerturbationSettings.Data(5) = h.PerturbationSettings.Data(4) -...
%     mywidth(2);

% shrink target Zone if needed
% if h.ShrinkTargetLocations.Value
%     h.locations_per_zone.Data(1) = round(sum(h.locations_per_zone.Data) * (h.ZoneLimitSettings.Data(1)*2)/total_range);
%     h.locations_per_zone.Data(3) = 80 - sum(h.locations_per_zone.Data(1:2));
% end
%h.TargetDefinition.Data = h.NewTargetDefinition.Data;

% update target locations
h.locations_per_zone.Data(1) = floor(h.ZoneLimitSettings.Data(1)/((h.TrialSettings.Data(1) - h.minimumtarget)/(h.MotorLocations + 0.5)));
        
end