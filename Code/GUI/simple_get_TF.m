alltargets = [1:0.25:3.75];
gain = 1;

for i = 1:12

target = alltargets(i);
lever_max = 4.8000;
lever_min = 0.2;
minimumtarget = 1;
total_motor_locations = 100;
TF_bins = 100;
MotorLocations = 115;

% calculate stepsize - lever displacement corresponding to one location
stepsize = (lever_max - minimumtarget)/(total_motor_locations + 0.5);
% gain = 0.4255;
gain = .37;
stepsize = stepsize*gain;
start_location = numel(target:stepsize:lever_max);
end_location = -numel(target:-stepsize:lever_min);
TF = linspace(end_location,start_location,TF_bins);

% % compute number of locations to be allocated to the target zone
% h.locations_per_zone.Data(1) = round(zone_width/stepsize);
%             
%         
% 
% % update zones outside the target zone
% % note: h.locations_per_zone.Data(2) is always 0 - locations to be skipped
% h.locations_per_zone.Data(3) = h.MotorLocations - sum(h.locations_per_zone.Data(1:2));
        
% safetychecks
TF = round(TF);
TF(TF>MotorLocations) = MotorLocations;
TF(TF<-MotorLocations) = MotorLocations;
        
% if ~h.current_trial_block.Data(1)
%     TF = -TF; % invert the TF
% end

AllTFs(:,i) = TF;
end