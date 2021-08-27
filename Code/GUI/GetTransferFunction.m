function [TF, h] = GetTransferFunction(h)

TF_bins = h.TransferFunction.Data(1);
TF = zeros(1,TF_bins);

lever_max = h.TrialSettings.Data(1); %triggerUpLim
lever_min = h.TrialSettings.Data(2); %triggerLowLim
target = h.TargetDefinition.Data(2);
zone_width = h.ZoneLimitSettings.Data(1);
gain = h.TFgain.Data;

switch h.TFtype.Value
    case 0 % variable gain

        total_motor_locations = h.MotorLocations;
        
        lever = linspace(h.DAC_levels.Data(1),h.DAC_levels.Data(2),TF_bins);
        
        % assign corresponding motor locations
        TF(lever<=lever_min) = -total_motor_locations;
        
        temp = find((lever>lever_min)&(lever<=target));
        TF(temp) = linspace(-total_motor_locations,0,numel(temp));
        
        temp = find((lever>=target)&(lever<lever_max));
        TF(temp) = linspace(0,total_motor_locations,numel(temp));
        
        TF(lever>=lever_max) = total_motor_locations;
        
        % updates locations in target zone
        h.locations_per_zone.Data(1) = round(total_motor_locations*zone_width*2/...
            (lever_max-lever_min));

    case 1 % fix speed
        
        total_motor_locations = h.MotorLocationsFixSpeed;
        
        % calculate stepsize - lever displacement corresponding to one location
        stepsize = (lever_max - h.minimumtarget)/(total_motor_locations + 0.5);
        % compute number of locations to be allocated to the target zone
        h.locations_per_zone.Data(1) = round(zone_width/stepsize);
        
        % rescale stepsize if needed for gain perturbation trials
        stepsize = stepsize*gain;
        
        start_location = numel(target:stepsize:lever_max);
        end_location = -numel(target:-stepsize:lever_min);
        TF = linspace(end_location,start_location,TF_bins);

end

% update zones outside the target zone
% note: h.locations_per_zone.Data(2) is always 0 - locations to be skipped
h.locations_per_zone.Data(3) = h.MotorLocations - sum(h.locations_per_zone.Data(1:2));
        
% safetychecks
TF = round(TF);
TF(TF>h.MotorLocations) = h.MotorLocations;
TF(TF<-h.MotorLocations) = -h.MotorLocations;

% find target definition if its a gain perturbation trial
if gain ~= 1
    lever = linspace(0,5,TF_bins);
    h.TargetDefinition.Data(1) = lever(find(TF>=h.locations_per_zone.Data(1),1));
    h.TargetDefinition.Data(3) = lever(find(TF>=-h.locations_per_zone.Data(1),1));
end

if ~h.current_trial_block.Data(1)
    TF = -TF; % invert the TF
end

end