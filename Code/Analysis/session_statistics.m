function [Histogram] = session_statistics(LeverTruncated, TrialInfo, ZonesToUse, Odors, DoPlot)

if nargin < 5
    DoPlot = 0;
end

%% make histogram of all trials for a given odor & target zone type
bins = 10;
%for i = 1:numel(Odors)
i = 1;
    for j = 1:numel(ZonesToUse)
%         f1 =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) ); % all trials
%         f2 =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==1); % successes
%         f3 =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==0); % failures
        f1 =  find ((TrialInfo.TargetZoneType==ZonesToUse(j)) ); % all trials
        f2 =  find ((TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==1); % successes
        f3 =  find ((TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==0); % failures
        
        for k = 1:3
            Temp = LeverTruncated(eval(['f',num2str(k)]),:);
            Temp = Temp(~isnan(Temp));
            Histogram.(['Odor',num2str(Odors(i))]).(['TZ',num2str(j)])(k,:) = hist(Temp,bins);
        end
    end
%end

%% plot the histograms
if DoPlot
    
    figure('name','Histograms');
    for i = 1%:numel(Odors)
        for j = 1:numel(ZonesToUse)
            cmat = [0 0 0];
            cmat(j) = 1;
            H =  Histogram.(['Odor',num2str(Odors(i))]).(['TZ',num2str(j)]);
            
            subplot(1,numel(Odors),i); hold on
%            plot(1:bins, H(1,:)/sum(H(1,:)), 'color', cmat, 'Linewidth', 1);
             plot(1:bins, H(2,:)/sum(H(2,:)), 'color', cmat/2, 'Linewidth', 1);
%             plot(1:bins, H(3,:)/sum(H(3,:)), 'color', cmat, 'LineStyle',':');
            
        end
    end
    
end


end