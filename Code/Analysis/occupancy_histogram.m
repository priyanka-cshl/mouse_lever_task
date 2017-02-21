function [Histogram] = occupancy_histogram(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, DoPlot)
global MyFileName;

if nargin < 5
    DoPlot = 0;
end

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
        counts(j,k) = size(Temp,1);
        Temp = Temp(~isnan(Temp));
        Histogram.(['TZ',num2str(j)])(k,:) = hist(Temp,bins);
    end
    
end

%% plot the histograms
if DoPlot
    MyTitle = {'All trials', 'Rewarded', 'Failures'};
    figure('name',[char(MyFileName),'OccupancyHistograms']);
    for k = 1:2%3
        %subplot(1,3,k); hold on
        subplot(1,2,k); hold on
        %set(gca,'Title',char(MyTitle(k)));
        %set(gca,'Title',char(MyTitle(k+1)));
        current_title = char(MyTitle(k+1));
        % mark the three target zones
        for j = 1:numel(ZonesToUse)
            cmat = [0 0 0];
            cmat(j) = 1;
            fill([TargetZones(j,2) TargetZones(j,2) TargetZones(j,1) TargetZones(j,1)], ...
                [0 0.25 0.25 0],cmat/2,'FaceAlpha',0.1,'EdgeColor','none')
        end
        for j = 1:numel(ZonesToUse)
            cmat = [0 0 0];
            cmat(j) = 1;
            [H] =  Histogram.(['TZ',num2str(j)]);
            X = (5/bins):(5/bins):5;
            plot(X, H(k+1,:)/sum(H(k+1,:)), 'color', cmat/2, 'Linewidth', 1);
            %plot(X, H(k,:)/sum(H(k,:)), 'color', cmat/2, 'Linewidth', 1);
            current_title= [current_title,' : ',num2str(counts(j,k+1)) ];
        end
        ax = gca;
        ax.Title.String = current_title;
    end
end

end