function [TF_out] = GetAllTransferFunctions(params, TargetZones)

DAC_limits = [0 5];
TriggerLim = params(1,9:10);
Zone_limits = params(1,21:23);
bins = params(1,29);
TF_out = zeros(size(TargetZones,1),bins);
for i = 1:size(TargetZones,1)
    target_limits = [TriggerLim(1) TargetZones(i,[3 2 1]) TriggerLim(2)];
    [TF] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,bins);
    TF_out(i,:) = TF(length(TF):-1:1)'/max(TF);
end
end
