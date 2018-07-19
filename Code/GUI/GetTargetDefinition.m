function [h] = GetTargetDefinition(h)

switch h.TFtype.Value
    case 0 % variable gain
        % readjust target zone upper and lower limits in proportion to the
        % partitioning of the available lever range
        
        total_range = h.TrialSettings.Data(1) - h.TrialSettings.Data(2); % in volts
        % available lever space - upper and lower 'halves' - normalized
        mywidth(1) = (h.TrialSettings.Data(1) - h.TargetDefinition.Data(2))/total_range;
        mywidth(2) = 1 - mywidth(1);
        % target zone widths (normalized) - - upper and lower 'halves'
        mywidth = 2*mywidth*h.ZoneLimitSettings.Data(1);

    case 1 % fix speed
        
        % uniform gain above and below the target zone
        mywidth(1) = h.ZoneLimitSettings.Data(1);
        mywidth(2) = mywidth(1); 
end

h.TargetDefinition.Data(1) = h.TargetDefinition.Data(2) + mywidth(1);
h.TargetDefinition.Data(3) = h.TargetDefinition.Data(2) - mywidth(2);

h.fake_target_zone.Data(1) = h.fake_target_zone.Data(2) + mywidth(1);
h.fake_target_zone.Data(3) = h.fake_target_zone.Data(2) - mywidth(2);
        
end