MotorBinsize = 8;
Motorbins = (-120:MotorBinsize:120);

plotrows = 4;
plotcols = 3;
% for unit = 1:size(spiketimes,2)
    [FullHistogram, SpikeHistogram, OdorHistogram] = LeverSpikeHistograms(unit, Traces, TrialInfo, spiketimes);
    
%     if any(TrialInfo.Perturbation(:,1)==11)
%         [FullHistogram2, SpikeHistogram2, OdorHistogram2] = LeverSpikeHistograms(unit, Traces, TrialInfo, spiketimes, 11);
%     end
    
    figure;
    set(gcf,'Position',[680   314   952   655]);
    X = colormap(brewermap([100],'Greys'));
    backcolor = [0.9 0.9 0.9];
    for i = 1:3
        
        % plot the behavior - lever histogram
        subplot(plotrows,plotcols,i); 
        h = imagesc(squeeze(FullHistogram(i,:,:))); 
        set(h,'AlphaData',~isnan(squeeze(FullHistogram(i,:,:))));
        set(gca,'Color',backcolor);
        set(gca,'YTick', [], 'XTick', []); 
        set(gca,'XDir','reverse');
        axis('square'); 
        
        % plot the spike histogram - w.r.t. lever bins
        subplot(plotrows,plotcols,i+plotcols);
        h = imagesc(squeeze(SpikeHistogram(i,:,:)));
        set(h,'AlphaData',~isnan(squeeze(SpikeHistogram(i,:,:))));
        set(gca,'Color',backcolor);
        set(gca,'YTick', [], 'XTick', []); 
        set(gca,'XDir','reverse');
        axis('square'); 
        
        % plot the spike histogram - w.r.t. odor locationbins
        subplot(plotrows,plotcols,i+2*plotcols);
        h = imagesc(squeeze(OdorHistogram(i,:,:)));
        set(h,'AlphaData',~isnan(squeeze(OdorHistogram(i,:,:))));
        set(gca,'Color',backcolor);
        set(gca,'YTick', [], 'XTick', []); 
        axis('square'); 
        
        % plot odor tuning
        subplot(plotrows,plotcols,i+3*plotcols);
        tuningcurve = nanmean(squeeze(OdorHistogram(i,:,:)),1);
        x_ind = Motorbins(find(~isnan(tuningcurve)));
        tuningcurve = tuningcurve(find(~isnan(tuningcurve)));
        
        % plot(x_ind,tuningcurve,'r'); hold on
        plot(x_ind,convPSTH(tuningcurve,2),'k'); 
        %plot(Motorbins(1:end-1),convPSTH(nanmean(squeeze(OdorHistogram(i,:,:)),1),5),'color',X(end,:));
        set(gca,'XLim',[Motorbins(1) Motorbins(end-1)]);
        axis('square'); 
        
    end
    
%     keyboard
% end

for i = 10:1:12; subplot(plotrows,plotcols,i); set(gca,'YLim', [0 100]); end