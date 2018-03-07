function [TF_out] = GetAllTransferFunctions(params, TargetZones, whichcase)

if nargin<3
    whichcase = 'fixedstart';
end

DAC_limits = [0 5];
TriggerLim = params(1,9:10);
Zone_limits = [params(1,21), 0, params(1,23)];
MotorLocations = params(1,22) - 1;
bins = params(1,29);
if bins == 0
    bins = 100;
end
TF_out = zeros(size(TargetZones,1),bins);
for i = 1:size(TargetZones,1)
    target_limits = [TriggerLim(1) TargetZones(i,[3 2 1]) TriggerLim(2)];
    switch whichcase
        case 'fixedstart'
            [TF] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,bins);
            TF = TF/max(TF);
        case 'fixedspeed'
            [TF] = LeverTransferFunction_fixspeed(target_limits,140,bins);
            TF(TF>MotorLocations) = MotorLocations;
            TF(TF<-MotorLocations) = -MotorLocations;
            TF = TF/MotorLocations;
    end
    TF_out(i,:) = TF(length(TF):-1:1)'; %/max(TF);
end
end
