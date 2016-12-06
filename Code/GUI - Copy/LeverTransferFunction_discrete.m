function [x] = LeverTransferFunction_discrete(target_limits, DAC_limits, Zone_limits, total_locations)
    
    min_val = target_limits(1);
    bound_1 = target_limits(2);
    target = target_limits(3);
    bound_2 = target_limits(4);
    max_val = target_limits(5);
    
    
    if nargin<3
        total_locations = 100;
    end
    
    % make a vector of lever positions (Volts)
    x = linspace(DAC_limits(1),DAC_limits(2),total_locations);
    % allocate zone identities
    x(x<=min_val) = 0;
    x((x>0)&(x<bound_1)) = -1;
    x((x>0)&(x<=bound_2)) = -2;
    x(x>0) = -3;
    x = abs(x);
    
    total_motor_locations = sum(Zone_limits);
    
    % target zone
    temp = find(x(1,:)==2);
    x(2,temp) = round(linspace(-Zone_limits(1),Zone_limits(1),length(temp)));
    
    % off target (high)
    temp = find(x(1,:)==3);
    x(2,temp) = round(linspace((Zone_limits(1)+Zone_limits(2)+1),total_motor_locations,length(temp)));
    
    % off target (low)
    temp = find(x(1,:)==1);
    x(2,temp) = round(linspace(-total_motor_locations,-(Zone_limits(1)+Zone_limits(2)+1),length(temp)));
    
    % below threshold
    temp = find(x(1,:)==0);
    x(2,temp) = -total_motor_locations;
        
    x(1,:) = [];
end