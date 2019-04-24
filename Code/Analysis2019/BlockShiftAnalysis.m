
x_ind = 0;
mydiffs = [];
isperturbed = 0;
blockshift = [];
%figure;
for mytrial = 1:numel(TrialInfo.TrialID)
    % use only valid trials
    if TrialInfo.Valid(mytrial)~=-1
        x_ind = x_ind + 1;
        % get Lever trace
        temp = cell2mat(Traces.Lever(mytrial));
        start_idx = TrialInfo.TimeIndices(mytrial,1);
        thisTrialRewards = cell2mat(TrialInfo.Reward(mytrial));
        if ~isempty(thisTrialRewards) && any(thisTrialRewards>0)
            reward = thisTrialRewards(find(thisTrialRewards>0,1,'first')); % in seconds w.r.t. trace start
        else
            reward = TrialInfo.Timestamps(mytrial,2);
        end
        stop_idx = min(reward,TrialInfo.Timestamps(mytrial,2));
        stop_idx = floor(500*stop_idx); % convert to indices
        start_idx = stop_idx - round((stop_idx - start_idx)/4); % last quarter of the trial
        Lever = temp(start_idx:stop_idx);
        
        % calculate time spent in each possible target zone sized zone
        zones = 0:0.25:5;
        counts = zeros(numel(zones),1);
        for x = 1:numel(zones)
            lowlim = max(0,zones(x)-0.3);
            uplim = min(5,zones(x)+0.3);
            counts(x,1) = numel(find(Lever>lowlim & Lever<=uplim));
        end
        favoriteZone = zones(find(counts==max(counts),1,'first'));
        thisTrialZone = TargetZones(TrialInfo.TargetZoneType(mytrial),2);
        
        switch TrialInfo.Perturbation(mytrial,1)
            case 0 % control
                Lever = Lever - thisTrialZone;
%                 thisTrialZone = counts(find(counts==thisTrialZone));
%                 subplot(2,1,1); hold on
%                 plot(x_ind,favoriteZone-thisTrialZone,'.r');
                subplot(2,1,2); hold on
                line([x_ind x_ind],mean(Lever)+[-std(Lever) std(Lever)],'color','r');
                plot(x_ind,mean(Lever),'.k');
                %errorbar(x_ind,mean(Lever),std(Lever),'r');
            case 11 % block shift
                thisTrialZone = thisTrialZone+0.9;
                Lever = Lever - thisTrialZone;
%                 subplot(2,1,1); hold on
%                 plot(x_ind,favoriteZone-thisTrialZone,'.b');
                subplot(2,1,2); hold on
                line([x_ind x_ind],mean(Lever)+[-std(Lever) std(Lever)],'color','b');
                plot(x_ind,mean(Lever),'.k');
                %errorbar(x_ind,mean(Lever),std(Lever),'b');
        end
        
        if isperturbed ~= TrialInfo.Perturbation(mytrial,1)
            blockshift = [blockshift; [mytrial TrialInfo.SessionTimestamps(mytrial,1)]];
            isperturbed = TrialInfo.Perturbation(mytrial,1);
        end
        
        mydiffs(x_ind,1) = mean(Lever);
        mydiffs(x_ind,2) = TrialInfo.Perturbation(mytrial,1)==11;
        
    end
end
line([0 x_ind],-0.3+[0 0],'LineStyle',':','color','k')
line([0 x_ind],0.3+[0 0],'LineStyle',':','color','k')
subplot(2,1,1); set(gca,'XLim',[0 x_ind]);
subplot(2,1,2); set(gca,'XLim',[0 x_ind],'YLim',[-2.5 2.5]);
set(gcf,'Position',[680   383   932   586]);
% figure; hold on
% blocksize = 5;
% for i = blocksize:blocksize:x_ind
%     if mode(mydiffs(i-blocksize+1:i,2)) == 0
%         errorbar(i/blocksize,mean(mydiffs(i-blocksize+1:i,1)),std(mydiffs(i-blocksize+1:i,1)),'r');
%     else
%         errorbar(i/blocksize,mean(mydiffs(i-blocksize+1:i,1)),std(mydiffs(i-blocksize+1:i,1)),'b');
%     end
% end
% line([0 x_ind/blocksize],[0 0],'LineStyle',':','color','k')

