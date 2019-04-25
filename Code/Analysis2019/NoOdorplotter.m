MotorBinsize = 8;
Motorbins = (-120:MotorBinsize:120);

plotcols = 6;
for unit = 1:size(spiketimes,2)
    [FullHistogram, SpikeHistogram, OdorHistogram] = LeverSpikeHistograms(unit, Traces, TrialInfo, spiketimes);
    [FullHistogram2, SpikeHistogram2, OdorHistogram2] = LeverSpikeHistograms(unit, Traces, TrialInfo, spiketimes, 11);
    figure;
    set(gcf,'Position',[680   314   952   655]);
    colormap(brewermap([],'*Greys'));
    for i = 1:3
        subplot(5,plotcols,i); 
        imagesc(squeeze(FullHistogram(i,:,:))); 
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        subplot(5,plotcols,i+plotcols+3);
        imagesc(squeeze(SpikeHistogram(i,:,:)));
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        subplot(5,plotcols,i+plotcols);
        imagesc(squeeze(OdorHistogram(i,:,:)));
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        subplot(5,plotcols,i+plotcols*2);
        imagesc(squeeze(FullHistogram2(i,:,:)));
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        subplot(5,plotcols,3+i+plotcols*3);
        imagesc(squeeze(SpikeHistogram2(i,:,:)));
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        subplot(5,plotcols,i+plotcols*3);
        imagesc(squeeze(OdorHistogram2(i,:,:)));
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        subplot(5,plotcols,i+plotcols*4);
        plot(Motorbins(1:end-1),nanmean(squeeze(OdorHistogram(i,:,:)),1),'r');
        %MyShadedErrorBar(Motorbins(1:end-1),nanmean(squeeze(OdorHistogram(i,:,:)),1),nanstd(squeeze(OdorHistogram(i,:,:)),1),'k');
        hold on
        plot(Motorbins(1:end-1),nanmean(squeeze(OdorHistogram2(i,:,:)),1),'b');
        %MyShadedErrorBar(Motorbins(1:end-1),nanmean(squeeze(OdorHistogram2(i,:,:)),1),nanstd(squeeze(OdorHistogram2(i,:,:)),1),'r');
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
    end
    
    keyboard
end