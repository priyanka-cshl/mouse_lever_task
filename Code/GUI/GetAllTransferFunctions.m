function [allTFs] = GetAllTransferFunctions()

AllTargets = 1:0.25:3.75;

% initialize h
h.TransferFunction.Data(1) = 100;
h.TrialSettings.Data(1) = 4.8;
h.TrialSettings.Data(2) = 0.2;
h.ZoneLimitSettings.Data(1) = 0.3;
h.TFgain.Data = 1;
h.MotorLocationArduinoMax = 120;
h.MotorLocations = 115;
h.MotorLocationsFixSpeed = 100;
h.minimumtarget = 1;
h.TFtype.Value = 1;
h.locations_per_zone.Data(1:2) = [8 0];
h.current_trial_block.Data(1) = 1;

for i = 1:numel(AllTargets)
    h.TargetDefinition.Data(2) = AllTargets(i);
    [TF, h] = GetTransferFunction(h);
    %TF = TF'+ h.MotorLocationArduinoMax + 1;
    allTFs(:,i) = TF;
end

end