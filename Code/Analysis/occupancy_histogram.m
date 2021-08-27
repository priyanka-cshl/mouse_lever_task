function [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, Params, DoPlot)
global MyFileName;

if nargin < 5
    DoPlot = 0;
end

% find the high cutoff - ignore points in the trial trigger zone
threshold = Params(1,10);

%% make histogram of all trials for a given odor & target zone type
bins = 20;
counts = zeros(3,3);
for j = 1:numel(ZonesToUse)
    %         f1 =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) ); % all trials
    %         f2 =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==1); % successes
    %         f3 =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==0); % failures
    f1 =  find ((TrialInfo.TargetZoneType==ZonesToUse(j)) ); % all trials
    f2 =  find ((TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==1); % successes
    f3 =  find ((TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==0); % failures
    for k = 1:3
        Temp = LeverTruncated(eval(['f',num2str(k)]),:);
        % ignore points above threshold 
        Temp(Temp>=threshold) = NaN;
        counts(j,k) = size(Temp,1); % keep count of trials
        Temp = Temp(~isnan(Temp));
        Histogram.(['TZ',num2str(j)])(k,:) = hist(Temp,bins);
    end
    
end

%% plot the histograms
if DoPlot
    figure('name',[char(MyFileName),'OccupancyHistograms']);
    for k = 1:3
        subplot(1,3,k); hold on
        % mark the three target zones
        for j = 1:numel(ZonesToUse)
            fill([TargetZones(j,2) TargetZones(j,2) TargetZones(j,1) TargetZones(j,1)], ...
                [0 0.25 0.25 0], ZoneColors(ZonesToUse(j)) ,'FaceAlpha',0.4,'EdgeColor','none')
            % annotate trial counts
            text(mean(TargetZones(j,1:2)) - 0.3, 0.23, num2str(counts(j,k)), 'color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
        end
        for j = 1:numel(ZonesToUse)
            [H] =  Histogram.(['TZ',num2str(j)]);
            X = (5/bins):(5/bins):5;
            plot(X, H(k,:)/sum(H(k,:)), 'color', ZoneColors(10+ZonesToUse(j)), 'Linewidth', 2);
        end
        axis square
        set(gca, 'TickDir', 'out', 'XLim', [0 5], 'XTick', [0 5], 'YLim', [0 0.25], 'YTick', [0 0.25], 'Box', 'on', 'Linewidth', 2, 'FontSize', 10, 'FontWeight', 'bold');
    end
end

end