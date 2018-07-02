function [idx] = MapRotaryEncoderToTFColorMapOpenLoop(h,motor_location,whichcase)

% motor_location is in Volts
% convert to motor position
motor_location = (motor_location - h.Rotary.Limits(3))/(h.Rotary.Limits(1)-h.Rotary.Limits(3));
motor_location = (motor_location*2*h.MotorLocations) - h.MotorLocations;
% 
if nargin < 3
    % normalize motor location to max
    motor_location = motor_location/h.MotorLocations;
    
    
    % get a signed color map
%     if h.current_trial_block.Data(1)
%         [~,foo] = min(h.TF_plot.CData);
%         MyMap = h.TF_plot.CData;
%         MyMap(foo:end,1) = -1*MyMap(foo:end,1);
%         [~,idx] = min(abs(MyMap-motor_location));
%         idx = 100 - idx;
%     else
        MyMap = flipud(h.TF_plot.CData);
        %MyMap(foo:end,1) = -1*MyMap(foo:end,1);
        [~,idx] = min(abs(MyMap-motor_location));
        %idx = 100 - idx;
%     end
else
    idx = motor_location; % for data rescaling
end

end