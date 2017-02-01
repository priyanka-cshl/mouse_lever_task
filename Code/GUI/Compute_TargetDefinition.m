
function [h] = Compute_TargetDefinition(h)
% compute new target zone definition
h.NewTargetDefinition.Data(1) = h.NewTargetDefinition.Data(2) +...
    h.ZoneLimitSettings.Data(1)+...
    h.NewTargetDefinition.Data(2)*h.ZoneLimitSettings.Data(2);
h.NewTargetDefinition.Data(3) = h.NewTargetDefinition.Data(2) -...
    h.ZoneLimitSettings.Data(1)-...
    h.NewTargetDefinition.Data(2)*h.ZoneLimitSettings.Data(2);

h.PertubationSettings.Data(3) = h.PertubationSettings.Data(4) +...
    h.ZoneLimitSettings.Data(1)+...
    h.PertubationSettings.Data(4)*h.ZoneLimitSettings.Data(2);
h.PertubationSettings.Data(5) = h.PertubationSettings.Data(4) -...
    h.ZoneLimitSettings.Data(1)-...
    h.PertubationSettings.Data(4)*h.ZoneLimitSettings.Data(2);
end