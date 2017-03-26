function [h] = Compute_TargetDefinition(h)
% compute new target zone definition
h.NewTargetDefinition.Data(1) = h.NewTargetDefinition.Data(2) +...
    h.ZoneLimitSettings.Data(1);
h.NewTargetDefinition.Data(3) = h.NewTargetDefinition.Data(2) -...
    h.ZoneLimitSettings.Data(1);

h.PerturbationSettings.Data(3) = h.PerturbationSettings.Data(4) +...
    h.ZoneLimitSettings.Data(1);
h.PerturbationSettings.Data(5) = h.PerturbationSettings.Data(4) -...
    h.ZoneLimitSettings.Data(1);

% shrink target Zone if needed
if h.ShrinkTargetLocations.Value
    h.locations_per_zone.Data(1) = round(sum(h.locations_per_zone.Data) * (h.ZoneLimitSettings.Data(1)*2)/5);
    h.locations_per_zone.Data(3) = 80 - sum(h.locations_per_zone.Data(1:2));
end

end