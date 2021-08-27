function [TF_out] = GetAllTransferFunctions(params, TargetZones, whichcase)

if nargin<3
    whichcase = 'fixedstart';
end

DAC_limits = [0 5];
TriggerLim = params(1,9:10);
Zone_limits = [params(1,21), 0, params(1,23)];
MotorLocations = params(1,22) - 1;
bins = 0; %params(1,29);
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
        case 'fixedgain'
            total_motor_locations = 100;
            max_motor_locations = 115;
            lever_max = DAC_limits(2) - 0.2;
            lever_min = DAC_limits(1) + 0.2;
            stepsize = (lever_max - 1)/(total_motor_locations + 0.5);
            target = TargetZones(i,2);
            start_location = numel(target:stepsize:lever_max);
            end_location = -numel(target:-stepsize:lever_min);
            TF = linspace(end_location,start_location,bins);
            
            TF = round(TF);
            TF(TF>max_motor_locations) = max_motor_locations;
            TF(TF<-max_motor_locations) = -max_motor_locations;
    end
    TF_out(i,:) = TF(length(TF):-1:1)'; %/max(TF);
end
end
