function [Trajectories] = OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, figureHandle1, Handedness)
% plot all (or many) trajectories, separate failures and rewards and
% perturbations
if nargin<6
    Handedness = 0; % All TFs together, 1 = left only, 2 = right only
end

%% Align all trajectories to the time-point when they start moving the lever
% ie. lever voltage goes below thershold for Trigger ON = ~4.8V
LeverReAligned = []; idx = [];
for i = 1:size(LeverTruncated,1) % each trial
    temp = LeverTruncated(i,:);
    t = find(temp<4.75, 1);
    if ~isempty(t)
        temp = [temp(t:end) NaN*ones(1,t-1)];
        LeverReAligned = [LeverReAligned; temp];
        idx = [idx; i];
    end
end

% keep only idx-s for the user-desired left or right TF functions
switch Handedness
    case 0
    case 1 % Left only
        idx = intersect(idx, find(TrialInfo.TransferFunctionLeft));
    case 2
        idx = intersect(idx, find(~TrialInfo.TransferFunctionLeft));
end

%% sort trajectories by zones, separate successes, failures, and perturbations.

% create a logical vector to get values of perturbed zones
myfakezone = cell2mat(cellfun(@(x) max([x; 0]), TrialInfo.FakeZone, 'UniformOutput', false))';

% go zone-by-zone and group trajectories (trialIDs) into All - unperturbed,
% rewarded - unpertubed, failures - unperturbed, and perturbed
for Z = 1:numel(ZonesToUse)
    % find all trials of the given TF
    total_trials = intersect(idx, find(TrialInfo.TargetZoneType==ZonesToUse(Z)));
    % only keep trials where there was no perturbation
    all_trials = intersect(total_trials, find(myfakezone==0));
    % successes
    successes = intersect(all_trials, find(TrialInfo.Success==1));
    % failures
    failures = intersect(all_trials, find(TrialInfo.Success==0));
    % all trials that were perturbed
    perturbed = intersect(total_trials, find(myfakezone>0));
    % all trials where the fake zone was the same
    fake = intersect(idx, find(myfakezone==ZonesToUse(Z)));
    
    Trajectories.TrialIDs.All(Z) = {all_trials};
    Trajectories.TrialIDs.Successes(Z) = {successes};
    Trajectories.TrialIDs.Failures(Z) = {failures};
    Trajectories.TrialIDs.Perturbed(Z) = {perturbed};
    Trajectories.TrialIDs.Fake(Z) = {fake};
    
    Trajectories.MeanTrace.All(Z) = { Mean_NoNaNs(LeverReAligned(all_trials,:)) };
    Trajectories.MeanTrace.Successes(Z) = { Mean_NoNaNs(LeverReAligned(successes,:)) };
    Trajectories.MeanTrace.Failures(Z) = { Mean_NoNaNs(LeverReAligned(failures,:)) };
    Trajectories.MeanTrace.Perturbed(Z) = { Mean_NoNaNs(LeverReAligned(perturbed,:)) };
    Trajectories.MeanTrace.Fake(Z) = { Mean_NoNaNs(LeverReAligned(fake,:)) };
end

%% Plot the trajectories

% x-axis (time-points)
mylim = [0 size(LeverReAligned,2)];
mylim(1) = -0.05*mylim(2);
mylim(2) = mylim(2) + abs(mylim(1));

TrajectoryColor = brewermap([numel(ZonesToUse)],'spectral');

if any(myfakezone)
    num_rows = 3;
else
    num_rows = 2;
end

Tags = {'Successes', 'Failures', 'Perturbed'};

for Z = 1:numel(ZonesToUse)
    % Run three loops, one each for all trials, Failures and perturbed
    for trialtype = 1:num_rows
        trialtag = Tags(trialtype);
        subplot_idx = Z + ((trialtype-1)*numel(ZonesToUse));
        % subplot initializations
        figure(figureHandle1);
        h = subplot(num_rows,numel(ZonesToUse),subplot_idx);
        hold on
        h.LineWidth = 1;
        h.Box = 'on';
        h.Title.String = [h.Title.String,',',...
        num2str(numel(cell2mat(Trajectories.TrialIDs.(char(trialtag))(Z))))]; % no. of trials being plotted
        
        % plot the mean and error bars
        MyTrace = cell2mat(Trajectories.MeanTrace.(char(trialtag))(Z));
        MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'r',[],0.5);

    end
end
end