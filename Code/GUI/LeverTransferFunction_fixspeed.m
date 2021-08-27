function [x] = LeverTransferFunction_fixspeed(target_limits, total_motor_locations, total_locations, min_target)
    
    min_val = target_limits(1);
    %bound_1 = target_limits(2);
    target = target_limits(3);
    %bound_2 = target_limits(4);
    max_val = target_limits(5);
    
    if nargin<2
        total_motor_locations = 80;
    end
    
    if nargin<3
        total_locations = 100;
    end
    
    if nargin<4
        min_target = 1;
    end
    
    % calculate stepsize - lever displacement corresponding to one location
    stepsize = (max_val-min_target)/(total_motor_locations + 0.5);
    start_location = numel(target:stepsize:max_val);
    end_location = -numel(target:-stepsize:min_val);
    
    x = linspace(end_location,start_location,total_locations);
end