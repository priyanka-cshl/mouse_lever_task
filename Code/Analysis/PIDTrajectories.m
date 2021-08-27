function [Trajectories] = PIDTrajectories(LeverTruncated, MotorTruncated, PIDTruncated, TrialInfo, ZonesToUse, TargetZones, Params, DoPlot, Handedness)
% plot all (or many) trajectories, separate failures and rewards and
% perturbations

DoPlot = 1;

%% Align all trajectories to the time-point when they start moving the lever
% ie. lever voltage goes below thershold for Trigger ON = ~4.8V
LeverReAligned = []; idx = []; MotorReAligned = []; PIDReAligned = [];
for i = 1:size(LeverTruncated,1) % each trial
    temp_lever = LeverTruncated(i,:);
    temp_motor = MotorTruncated(i,:);
    temp_pid = PIDTruncated(i,:);
    t = find(temp_lever<4.75, 1);
    if ~isempty(t)
        temp_lever = [temp_lever(t:end) NaN*ones(1,t-1)];
        temp_motor = [temp_motor(t:end) NaN*ones(1,t-1)];
        temp_pid = [temp_pid(t:end) NaN*ones(1,t-1)];
        LeverReAligned = [LeverReAligned; temp_lever];
        MotorReAligned = [MotorReAligned; temp_motor];
        PIDReAligned = [PIDReAligned; temp_pid];
        idx = [idx; i];
    end
end

%% sort trajectories by zones, separate successes, failures, and perturbations.
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
    perturbed = intersect(total_trials, find(myfakezone~=0));
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
    
    Trajectories.All(Z) = {LeverReAligned(all_trials,:)};
    Trajectories.Successes(Z) = {LeverReAligned(successes,:)};
    Trajectories.Failures(Z) = {LeverReAligned(failures,:)};
    Trajectories.Perturbed(Z) = {LeverReAligned(perturbed,:)};
    Trajectories.Fake(Z) = {LeverReAligned(fake,:)};
    
    PIDTrajectories.MeanTrace.All(Z) = { Mean_NoNaNs(PIDReAligned(all_trials,:)) };
    PIDTrajectories.MeanTrace.Successes(Z) = { Mean_NoNaNs(PIDReAligned(successes,:)) };
    PIDTrajectories.MeanTrace.Failures(Z) = { Mean_NoNaNs(PIDReAligned(failures,:)) };
    PIDTrajectories.MeanTrace.Perturbed(Z) = { Mean_NoNaNs(PIDReAligned(perturbed,:)) };
    PIDTrajectories.MeanTrace.Fake(Z) = { Mean_NoNaNs(PIDReAligned(fake,:)) };
    
    PIDTrajectories.All(Z) = {PIDReAligned(all_trials,:)};
    PIDTrajectories.Successes(Z) = {PIDReAligned(successes,:)};
    PIDTrajectories.Failures(Z) = {PIDReAligned(failures,:)};
    PIDTrajectories.Perturbed(Z) = {PIDReAligned(perturbed,:)};
    PIDTrajectories.Fake(Z) = {PIDReAligned(fake,:)};
    
end

if DoPlot
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
    
    % initialize the figure
    figureHandle1 = figure; % make a new figure
    %figureHandle2 = figure;
    
    for Z = 1:numel(ZonesToUse)
        % Run three loops, one each for all trials, Failures and perturbed
        for trialtype = 1%:num_rows
            trialtag = Tags(trialtype);
            subplot_idx = Z + ((trialtype-1)*numel(ZonesToUse));
            
            % subplot initializations
            figure(figureHandle1);
            h = subplot(num_rows,numel(ZonesToUse),subplot_idx);
            hold on
            h.LineWidth = 1;
            h.Box = 'on';
            h.TickDir = 'out';
            h.Title.String = num2str(numel(cell2mat(Trajectories.TrialIDs.(char(trialtag))(Z)))); % no. of trials being plotted
            
            % Plot the Target zone
            myzone = [ TargetZones(ZonesToUse(Z),[1 3]) TargetZones(ZonesToUse(Z),[3 1]) ];
            fill( [mylim(1) mylim(1) mylim(2) mylim(2)], myzone, [1 1 0],'FaceAlpha',0.2, 'EdgeColor', 'none');
            
            % plot the mean and error bars
            MyTrace = cell2mat(Trajectories.MeanTrace.(char(trialtag))(Z));
            MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'k',[],0.5);
            
            set(gca,'YLim',[0 5],'XLim',mylim,'Fontsize',12,'FontWeight','b');
            
            % plot PID data
            subplot_idx = Z + ((trialtype)*numel(ZonesToUse));
            
            % subplot initializations
            figure(figureHandle1);
            h = subplot(num_rows,numel(ZonesToUse),subplot_idx);
            hold on
            h.LineWidth = 1;
            h.Box = 'on';
            h.TickDir = 'out';
            h.Title.String = num2str(numel(cell2mat(Trajectories.TrialIDs.(char(trialtag))(Z)))); % no. of trials being plotted
            
            % plot PID traces
            MyTrace = cell2mat(PIDTrajectories.All(Z));
            
            
            
        end
        
        % Ticks and axis limits
        set(gca,'YLim',[0 5],'XLim',mylim,'Fontsize',12,'FontWeight','b');
        if Z == 1
            h.YTick = [0 5];
            h.YLabel.String = char(trialtag);
            h.YLabel.FontSize = 12;
        else
            h.YTick = [];
        end
        if trialtype == num_rows
            h.XTick = [0 1250]; % 1250 samples = 2.5 sec @ 500Hz
            h.XTickLabel = {'0', '2.5s'};
        else
            h.XTick = [];
        end
    end
end
end
end