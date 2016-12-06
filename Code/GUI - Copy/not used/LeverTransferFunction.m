function [TF_out, TF_plot] = LeverTransferFunction(target_limits, total_locations,steepness)
    
    min_val = target_limits(1);
    bound_1 = target_limits(2);
    target = target_limits(3);
    bound_2 = target_limits(4);
    max_val = target_limits(5);
    
    if nargin<2
        total_locations = 100;
        steepness = 0.5;
    end
    
    zone_1 = linspace(min_val,bound_1,1+ceil(total_locations/4));
    zone_1(end) = [];
    zone_1 = (pi/2)*(zone_1/max(zone_1));
    zone_2 = linspace(bound_1,target,ceil(total_locations/4)) - bound_1;
    zone_2 = (pi/2) + (pi/2)*(zone_2/max(zone_2));
    zone_3 = linspace(target,target - (bound_2-target),floor(total_locations/4))  -  (target - (bound_2-target));
    zone_3 = (pi/2) + (pi/2)*(zone_3/max(zone_3));
    zone_4 = linspace(5,bound_2,1+floor(total_locations/4)) - bound_2;
    zone_4(1) = [];
    zone_4 = (pi/2)*(zone_4/max(zone_4));
    
    Left = [zone_1 zone_2];
    Right = [zone_3 zone_4];
    
    x1 =  linspace(min_val,bound_1,1+floor(total_locations/4));
    x2 =  linspace(bound_1,target,floor(total_locations/4));
    x3 = linspace(target,bound_2,floor(total_locations/4));
    x4 = linspace(bound_2,max_val,1+floor(total_locations/4));
    
    TF(:,1) = [x1(1:end-1) x2 x3 x4(2:end)];

    TF_Left = diff(sin(Left));
    TF_Left = -1*(TF_Left - max(TF_Left))/(max(TF_Left)-min(TF_Left));
    TF_Right = diff(sin(Right));
    TF_Right = (TF_Right - min(TF_Right))/(max(TF_Right)-min(TF_Right));
    TF(:,2) = [TF_Left 1 1 TF_Right];
    TF(:,2) = power(TF(:,2),steepness)/max(power(TF(:,2),steepness));
    TF_plot = TF;
    TF(size(TF_Left,2)+2:end,2) = 2 - TF(size(TF_Left,2)+2:end,2);
            
    TF_out = interp1q(TF(:,1),TF(:,2),(min_val:(max_val-min_val)/total_locations:max_val)');
    TF_out = round(TF_out*floor(total_locations/2),0,'decimals');
end