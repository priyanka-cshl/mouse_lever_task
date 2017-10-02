function [Trajectories] = PlotTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, AllTFs, Handedness, DoPlot)
% plot all (or many) trajectories, separate failures and rewards and
% perturbations

if nargin<6
    Handedness = 0; % All TFs together, 1 = left only, 2 = right only
    DoPlot = 0;
elseif nargin<7
    DoPlot = 0;
end

%% Align all trajectories to the time-point when they start moving the lever
% ie. lever voltage goes below thershold for Trigger ON = ~4.8V
LeverReAligned = []; 
idx = [];
for i = 1:size(LeverTruncated,1) % each trial
    temp = LeverTruncated(i,:);
    t = find(temp<4.75, 1);
    if ~isempty(t)
        temp = [temp(t:end) NaN*ones(1,t-1)];
        LeverReAligned = [LeverReAligned; temp]; %#ok<*AGROW>
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

if DoPlot
    %% Plot the trajectories
    
    % x-axis (time-points)
    mylim = [0 size(LeverReAligned,2)];
    mylim(1) = -0.05*mylim(2);
    %mylim(2) = mylim(2) + abs(mylim(1));
    % add extra space on the right for the transfer function - 
    % ~0.1 times the plot size
    % width of transfer function axes = 2*abs(mylim(1))
    mylim(2) = mylim(2) + 3*abs(mylim(1)); 
    TFaxeswidth = 2*abs(mylim(1))/diff(mylim);
    
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
        for trialtype = 1:num_rows
            trialtag = Tags(trialtype);
            subplot_idx = Z + ((trialtype-1)*numel(ZonesToUse));
            
            % subplot initializations - trajectory plot
            figure(figureHandle1);
            h.trajectoryplot = subplot(num_rows,numel(ZonesToUse),subplot_idx);
            hold on
            h.trajectoryplot.LineWidth = 1;
            h.trajectoryplot.Box = 'on';
            h.trajectoryplot.Title.String = num2str(numel(cell2mat(Trajectories.TrialIDs.(char(trialtag))(Z)))); % no. of trials being plotted
            
            % plot all TargetZones

            h.TFaxes = axes;
            h.TFaxes.Position = h.trajectoryplot.Position;
            h.TFaxes.Position(1) = h.trajectoryplot.Position(1) + (1-TFaxeswidth)*h.trajectoryplot.Position(3);
            h.TFaxes.Position(3) = TFaxeswidth*h.trajectoryplot.Position(3);
            h.TFcolorbar = imagesc(((-50:1:50)')/50,[-1 1]);
            colormap(h.TFaxes, brewermap([17],'rdbu'));
            axis off tight
            set(h.TFaxes,'YLim',[0 100]);
            % plot the actual TF
            MyTF = AllTFs(Z,:);
            h.TFcolorbar.CData = MyTF';

%             for j = 1:numel(ZonesToUse)
%                 y = [ TargetZones(ZonesToUse(j),[1 3]) TargetZones(ZonesToUse(j),[3 1]) ];
%                 fill( [mylim(1) mylim(1) mylim(2) mylim(2)], y, ZoneColors(j), 'FaceAlpha', 0.4, 'EdgeColor', 'none');
%             end

            % reactivate the trajectory axes
            axes(h.trajectoryplot);
            % demarcate the active zone
%             line(mylim,TargetZones(ZonesToUse(Z),[1 1]),'color','k','LineStyle','--');
%             line(mylim,TargetZones(ZonesToUse(Z),[3 3]),'color','k','LineStyle','--');
            y = [ TargetZones(ZonesToUse(Z),[1 3]) TargetZones(ZonesToUse(Z),[3 1]) ];
            fill( [mylim(1) mylim(1) mylim(2) mylim(2)], y, [0.7294    0.8314    0.9569], 'FaceAlpha', 0.4, 'EdgeColor', 'none');
            
            % plot the mean and error bars
            MyTrace = cell2mat(Trajectories.MeanTrace.(char(trialtag))(Z));
            if numel(cell2mat(Trajectories.TrialIDs.(char(trialtag))(Z))) > 1
                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'k',[],0.5);
            else
                plot(1:size(MyTrace,2),MyTrace(1,:),'k'); % don't plot error if num of trials = 1
            end
            
            % Ticks and axis limits
            set(gca,'YLim',[0 5],'XLim',mylim,'Fontsize',12,'FontWeight','b');
            if Z == 1
                h.trajectoryplot.YTick = [0 5];
                h.trajectoryplot.YLabel.String = char(trialtag);
                h.trajectoryplot.YLabel.FontSize = 12;
            else
                h.trajectoryplot.YTick = [];
            end
            if trialtype == num_rows
                h.trajectoryplot.XTick = [0 1250]; % 1250 samples = 2.5 sec @ 500Hz
                h.trajectoryplot.XTickLabel = {'0', '2.5s'};
            else
                h.trajectoryplot.XTick = [];
            end
            
            % bring the TF axis on top
            axes(h.TFaxes);
        end
    end
end
end