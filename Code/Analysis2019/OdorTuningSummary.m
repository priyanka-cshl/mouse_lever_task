MotorBinsize = 8;
Motorbins = (-120:MotorBinsize:120);
SummaryHistogram = zeros(3,size(spiketimes,2),numel(Motorbins)-1);

plotrows = 4;
plotcols = 3;
for unit = 1:size(spiketimes,2)
    [FullHistogram, SpikeHistogram, OdorHistogram] = LeverSpikeHistograms(unit, Traces, TrialInfo, spiketimes);
    
%     if any(TrialInfo.Perturbation(:,1)==11)
%         [FullHistogram2, SpikeHistogram2, OdorHistogram2] = LeverSpikeHistograms(unit, Traces, TrialInfo, spiketimes, 11);
%     end
%     
%     figure;
%     set(gcf,'Position',[680   314   952   655]);
%     colormap(brewermap([],'*Greys'));
    
    for i = 1:3
        
%         % plot the behavior - lever histogram
%         subplot(plotrows,plotcols,i); 
%         imagesc(squeeze(FullHistogram(i,:,:))); 
%         set(gca,'YTick', [], 'XTick', []); 
%         axis('square'); 
%         
%         % plot the spike histogram - w.r.t. lever bins
%         subplot(plotrows,plotcols,i+plotcols);
%         imagesc(squeeze(SpikeHistogram(i,:,:)));
%         set(gca,'YTick', [], 'XTick', []); 
%         axis('square'); 
%         
%         % plot the spike histogram - w.r.t. odor locationbins
%         subplot(plotrows,plotcols,i+2*plotcols);
%         imagesc(squeeze(OdorHistogram(i,:,:)));
%         set(gca,'YTick', [], 'XTick', []); 
%         axis('square'); 
        
        % plot odor tuning
%         subplot(plotrows,plotcols,i+3*plotcols);
%         plot(Motorbins(1:end-1),nanmean(squeeze(OdorHistogram(i,:,:)),1),'r');
%         axis('square'); 
        
          SummaryHistogram(i,unit,:) = nanmean(squeeze(OdorHistogram(i,:,:)),1);
          SummaryHistogram(i,unit,:) = SummaryHistogram(i,unit,:)/max(SummaryHistogram(i,unit,:));
%         if any(TrialInfo.Perturbation(:,1)==11)
%             subplot(plotrows,plotcols,i+(round(plotcols/2)));
%             imagesc(squeeze(FullHistogram2(i,:,:)));
%             set(gca,'YTick', [], 'XTick', []);
%             axis('square');
%             
%             subplot(plotrows,plotcols,i+plotcols +(round(plotcols/2)));
%             imagesc(squeeze(SpikeHistogram2(i,:,:)));
%             set(gca,'YTick', [], 'XTick', []);
%             axis('square');
%             
%             subplot(plotrows,plotcols,i+2*plotcols +(round(plotcols/2)));
%             imagesc(squeeze(OdorHistogram2(i,:,:)));
%             set(gca,'YTick', [], 'XTick', []);
%             axis('square');
%             
%             subplot(plotrows,plotcols,i+3*plotcols +(round(plotcols/2)));
%             hold on
%             plot(Motorbins(1:end-1),nanmean(squeeze(OdorHistogram2(i,:,:)),1),'b');
%             axis('square');
%         end
    end
    
%     keyboard
end

figure;
for i = 1:3
    colormap(brewermap([],'*RdBu'));
    subplot(1,3,i);
    imagesc(squeeze(SummaryHistogram(i,:,:)));
    set(gca,'YTick', [], 'XTick', []);
end