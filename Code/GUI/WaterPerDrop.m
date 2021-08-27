function [WaterOut] = WaterPerDrop(h)
% water calibration (ms, ul per drop) as of 2018.09.05    
%     5.0000    0.3900
%    10.0000    0.8000
%    15.0000    1.0900
%    20.0000    1.5500
%    25.0000    2.1800
%    30.0000    2.8500
%    35.0000    3.6000
%    40.0000    4.3700
%    45.0000    5.1300
%    50.0000    5.9900

% fit using 2 degree polynomial
WaterOut = h.watercoeffs(1)*(h.RewardControls.Data(1)^2) + h.watercoeffs(2)*h.RewardControls.Data(1) + h.watercoeffs(3);
end