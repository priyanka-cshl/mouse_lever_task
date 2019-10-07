function NextTrial_Callback(h)

%% home motor if needed
if h.motor_home.BackgroundColor(1) == 0.5
    h.Arduino.write(72,'uint16');
end

global IsRewardedTrial;
global TrialsToPerturb;

disp(['---------- New Trial (#', num2str(h.current_trial_block.Data(2)),') ----------']);

%% update performance
h.ProgressReport.Data(:,3) = round(100*(h.ProgressReport.Data(:,2)./h.ProgressReport.Data(:,1)),0,'decimals');
h.ProgressReportPerturbed.Data(:,3) = round(100*(h.ProgressReportPerturbed.Data(:,2)./h.ProgressReportPerturbed.Data(:,1)),0,'decimals');

% reset TF gain
h.TFgain.Data = 1;

%% update mean hold times for each target zone
if h.which_target.Data
    f = find(h.hold_times.Data(:,1)==h.which_target.Data);
    if ~isempty(f)
        h.MeanHoldTimes.Data(h.which_target.Data) = floor(median(h.hold_times.Data(f,3)));
    end
end


%% invert TF if needed
h.current_trial_block.Data(1) = (rand(1)<h.TFLeftprobability.Data(1)); % 50% chance of inverting TF

%% update target level
% shuffle arrays of targets
h.target_level_array.Data = h.target_level_array.Data(randperm(length(h.target_level_array.Data)) );

% check if antibias needs to be implemented and if previous trial was a failure
NoAntiBias = 1;
if (h.AntiBias.Value && ~IsRewardedTrial && ~h.current_trial_block.Data(3))
    find(h.all_targets == h.TargetDefinition.Data(2));
    % find next closest targets
    similar_targets = h.target_level_array.Data(find(abs(h.target_level_array.Data - h.TargetDefinition.Data(2))<=0.25));
    if ~isempty(similar_targets)
        NoAntiBias = 0;
        disp('antibiasing');
        h.TargetDefinition.Data(2) = similar_targets(randi(numel(similar_targets)));
    end
end

if NoAntiBias
    if h.preloaded_sequence.Value
        foo = sort(h.target_level_array.Data);
        whichzone = 1 + mod(h.current_trial_block.Data(2)-1,numel(h.trialsequence));
        h.current_trial_block.Data(5) = h.holdtimes(whichzone);
        whichzone = h.trialsequence(whichzone);
        h.TargetDefinition.Data(2) = foo(whichzone);
    elseif ~h.PseudoRandomZones.Value
        h.TargetDefinition.Data(2) = h.target_level_array.Data(1);
    else
        unused_targets = h.target_level_array.Data(find(abs(h.target_level_array.Data-h.TargetDefinition.Data(2))>0.5));
        h.TargetDefinition.Data(2) = unused_targets(randi(numel(unused_targets)));
    end
end

h.which_target.Data = find(h.all_targets == h.TargetDefinition.Data(2)); 
h.thistarget.YData = h.which_target.Data;

%% update odor
if h.odor_priors.Value
    %which_target = h.which_target.Data;
    odor_probability = [zeros(60,1); ones(30,1)]; %2/3rds chance of being a priored odor, 1/3rd un-priored
    odor_probability = odor_probability(randperm(length(odor_probability)));
    if odor_probability(1)
        h.current_trial_block.Data(4) = 3; % odor 3
    else
        h.current_trial_block.Data(4) = 1 + ...
            (h.TargetDefinition.Data(2) > mean(h.target_level_array.Data)); % odor 2 if upper 6 zones, odor 1 if lower six zones
    end
else
    % no biases - any TF can be any odor - pick randomly
    odor_list = randperm(length(h.Odor_list.Value)); % shuffle odor list
    odor_list(find(odor_list==1)) = [];
    h.current_trial_block.Data(4) = h.Odor_list.Value(odor_list(1)) - 1;
end

%% update target hold time
if ~h.preloaded_sequence.Value
    if h.adaptive_holds.Value
        % get mean holds for this particular target zone
        h.current_trial_block.Data(5) = 25 + h.MeanHoldTimes.Data(h.which_target.Data);
        
        % constrain to lie within min and max hold times
        if h.current_trial_block.Data(5)<h.TargetHold.Data(1)
            h.current_trial_block.Data(5) = h.TargetHold.Data(1);
        elseif h.current_trial_block.Data(5)>h.TargetHold.Data(3)
            h.current_trial_block.Data(5) = h.TargetHold.Data(3);
        end

    else
        x = exprnd(h.TargetHold.Data(2));
        while (x + h.TargetHold.Data(1)) > h.TargetHold.Data(3)
            x = exprnd(h.TargetHold.Data(2));
        end
        h.current_trial_block.Data(5) = round(h.TargetHold.Data(1)+x,0);
    end
end

%% update trigger hold time
x = exprnd(h.TriggerHold.Data(2));
while (x + h.TriggerHold.Data(1)) > h.TriggerHold.Data(3)
    x = exprnd(h.TriggerHold.Data(2));
end
h.current_trial_block.Data(6) = round(h.TriggerHold.Data(1)+x,0);

%% feedback perturbation settings

% shuffle pertubation vector if needed
if (h.which_perturbation.Value>1) && ~mod(h.current_trial_block.Data(2),numel(TrialsToPerturb)) && (h.which_perturbation.Value~=11)
    TrialsToPerturb = TrialsToPerturb([randperm(floor(numel(TrialsToPerturb)/2)) ...
            floor(numel(TrialsToPerturb)/2)+(1:floor(numel(TrialsToPerturb)/2))]);
end

if (h.which_perturbation.Value>1) && (h.which_perturbation.Value~=11)
    % bsed on the user set probability: check if the trial is to be perturbed or not
    h.current_trial_block.Data(3) = TrialsToPerturb(mod(h.current_trial_block.Data(2),numel(TrialsToPerturb)) + 1);
    
    % if perturbation trial
    if h.current_trial_block.Data(3) %&& h.which_perturbation.Value>1
        h.hold_times.Data(h.current_trial_block.Data(2)-1,2) = NaN;
        switch h.which_perturbation.Value
            case 2 % decouple water and odor
                % select randomly a target level from a zone that's not of the target zone
                % and not too close to the actual sensory zone
                unused_targets = h.target_level_array.Data(find(abs(h.target_level_array.Data-h.TargetDefinition.Data(2))>0.5));
                h.fake_target_zone.Data(2) = unused_targets(randi(length(unused_targets)));
                h.fake_target_zone.ForegroundColor = [0 0 0];
                h.which_fake_target.Data = find(h.all_targets == h.fake_target_zone.Data(2));
                
            case 3 % no odor
                h.current_trial_block.Data(4) = 0;
                
            case 4 % flip map
                h.current_trial_block.Data(5) = 2000; % increase target hold time in this trial
                
            case {5, 6, 7} % location offset I, II and III
                
                % only applies to particular target zones and odors
                % pick a target zone randomly - either zone 6 (2.5) or zone
                % 7 (2.25)
                
                % if using odor biased TFs
                if h.odor_priors.Value
                    if rand(1)<0.5
                        h.TargetDefinition.Data(2) = h.PerturbationSettings.Data(4) - 0.25; % 2.25
                        % since its on of the lower TZs - pick from odor 1 or 3
                        if rand(1)<0.5
                            h.current_trial_block.Data(4) = 1; % odor 3
                        else
                            h.current_trial_block.Data(4) = 3; % odor 3
                        end
                    else
                        h.TargetDefinition.Data(2) = h.PerturbationSettings.Data(4); % 2.5
                        % since its on of the upper TZs - pick from odor 2 or 3
                        if rand(1)<0.5
                            h.current_trial_block.Data(4) = 2; % odor 3
                        else
                            h.current_trial_block.Data(4) = 3; % odor 3
                        end
                    end
                else
                    h.TargetDefinition.Data(2) = h.PerturbationSettings.Data(4);
                end
                    
%                 % so force current zone to TZ of choice and odor
%                 h.TargetDefinition.Data(2) = h.PerturbationSettings.Data(4);
%                 h.current_trial_block.Data(4) = 3; % odor 3
                
                % randomly choose if its an upward or a downward shift
                myoffset = h.myoffset.Data(1);
                if rand(1)<0.5
                    h.PerturbationSettings.Data(3) = -abs(myoffset);
                else
                    h.PerturbationSettings.Data(3) = abs(myoffset);
                end
                % sanity check to make sure there are not too many trials
                % of same type
                if abs(h.ProgressReportPerturbed.Data(4,1) - h.ProgressReportPerturbed.Data(6,1))>=2
                    if (h.ProgressReportPerturbed.Data(4,1) - h.ProgressReportPerturbed.Data(6,1)) > 0
                        % more +ve offsets done
                        h.PerturbationSettings.Data(3) = -abs(myoffset);
                    else
                        h.PerturbationSettings.Data(3) = abs(myoffset);
                    end
                end
                
                % only for offset III
                if rand(1)<0.5 && h.which_perturbation.Value == 7
                    h.PerturbationSettings.Data(3) = h.PerturbationSettings.Data(3) + round(h.PerturbationSettings.Data(3)/2);
                end
                
            case 8 % gain change
                if rand(1)<0.5
                    h.TFgain.Data = 0.37;
                    h.TargetDefinition.Data(2) = 3.5; % normally 1.25
                    h.PerturbationSettings.Data(3) = -1;
                else
                    %h.TFgain.Data = 2.5;
                    %h.TargetDefinition.Data(2) = 1.5;
                    h.TFgain.Data = 3;
                    h.TargetDefinition.Data(2) = 1;
%                     h.TFgain.Data = 2.5;
%                     h.TargetDefinition.Data(2) = 1.5; % normally 3.5
                    h.PerturbationSettings.Data(3) = 1;
                end
                % sanity check to make sure there are not too many trials
                % of same type
                if abs(h.ProgressReportPerturbed.Data(4,1) - h.ProgressReportPerturbed.Data(6,1))>=2
                    if (h.ProgressReportPerturbed.Data(4,1) - h.ProgressReportPerturbed.Data(6,1)) > 0
                        h.TFgain.Data = 2.5;
                        h.TargetDefinition.Data(2) = 1.5;
                        h.PerturbationSettings.Data(3) = 1;
                    else
                        h.TFgain.Data = 0.37;
                        h.TargetDefinition.Data(2) = 3.5;
                        h.PerturbationSettings.Data(3) = -1;
                    end
                end
                % assign odor thats opposite of what would normally be
                % assigned by target definiition
                h.current_trial_block.Data(4) = 1 + ...
                    (h.TargetDefinition.Data(2)<mean(h.target_level_array.Data)); % 2 if lower 6 zones, 1 if upper six zones
           
            case {9,10}
                % one of three target zones
                % 3.5, 2.5, 1.5
                h.TargetDefinition.Data(2) = randperm(3,1);
                switch floor(h.TargetDefinition.Data(2))
                    case 1
                        h.current_trial_block.Data(4) = 1;
                    case 2
                        h.current_trial_block.Data(4) = 3;
                    case 3
                        h.current_trial_block.Data(4) = 2;
                end
                
                
        end
    else
        h.fake_target_zone.ForegroundColor = [0.65 0.65 0.65];
    end
    
end

%% invoke target definition callback (this automatically calls Send2Arduino)
set(h.motor_home,'BackgroundColor',[0.94 0.94 0.94]);
guidata(h.hObject, h);
OdorLocatorTabbed('ZoneLimitSettings_CellEditCallback',h.hObject,[],h);

