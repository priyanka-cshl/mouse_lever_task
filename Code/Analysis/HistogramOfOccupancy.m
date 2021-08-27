function [] = HistogramOfOccupancy(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, AllTFs, Trajectories, DoPlot)
global MyFileName;
if nargin < 7
    DoPlot = 0;
end

ZonesToUse = flipud(ZonesToUse); % to make sure the TFs are plotted from top to bottom
Tags = {'All', 'Successes', 'Failures', 'Perturbed', 'Fake'};
myfakezone = cell2mat(cellfun(@(x) max([x; 0]), TrialInfo.FakeZone, 'UniformOutput', false))';

% find the high cutoff - ignore points in the trial trigger zone
threshold = [4.8 0.2];
LeverTruncated(LeverTruncated>=threshold(1)) = NaN;
LeverTruncated(LeverTruncated<=threshold(2)) = NaN;

%% Uncentered histograms (all TZs separate)
xbins = 0.2:0.24:4.8;
Motorbins = (-80:8:80);

for j = 1:numel(ZonesToUse)
    for k = 1:5
        whichtrials = cell2mat(Trajectories.TrialIDs.(char(Tags(k)))(j));
        Temp = LeverTruncated(whichtrials,:);
        Temp = Temp(~isnan(Temp));
        FullHistogram(k,j,:) = fliplr(hist(Temp,xbins));
        FullHistogram(k,j,:) = FullHistogram(k,j,:)/sum(FullHistogram(k,j,:));
        
        Temp = MotorTruncated(whichtrials,:);   
        Temp = Temp(~isnan(Temp));
        CenteredHistogramMotor(k,j,:) = fliplr(hist(Temp,Motorbins));
        CenteredHistogramMotor(k,j,:) = CenteredHistogramMotor(k,j,:)/sum(CenteredHistogramMotor(k,j,:));
    end 
end

num_rows = 3 + 2*~isempty(find(myfakezone));

%% plot the histograms
if DoPlot
    % plot histograms as 2d-color maps
    figure('name',[char(MyFileName),'HistScores']);
    colormap(brewermap([],'*Greys'));
    
    for k = 1:num_rows
        subplot_num = (k+1)*2; % 4,6,8,10
        
        if k == 1
            ax1 = subplot(num_rows+1,2,k);
            imagesc(AllTFs,[-1 1]);
            colormap(ax1, brewermap([161],'*RdBu'));
            set(gca,'YTick', [], 'XTick', []);
            
            ax2 = subplot(num_rows+1,2,2);
            AllTFs_remapped = repmat( linspace(-80,80,numel(Motorbins)) , numel(ZonesToUse), 1);  
            imagesc(AllTFs_remapped,[-80 80]);
            colormap(ax2, brewermap([161],'RdBu'));
            set(gca,'YTick', [], 'XTick', []);
        end
        
        subplot(num_rows+1,2, subplot_num - 1);
        imagesc(squeeze(FullHistogram(k,:,:)));
        for x = 1:numel(ZonesToUse) 
             xpoint = 20* (TargetZones(ZonesToUse(x),2))/(4.92-0.08);
             xpoint = 20 - xpoint;
             line(xpoint*[1 1],x+[-0.5 0.5],'color','r');
        end
        set(gca,'YTick', [], 'XTick', []);
        ax = gca;
        ax.YLabel.String = char(Tags(k));
        ax.YLabel.FontSize = 12;
        ax.YLabel.FontWeight = 'b';
        
        subplot(num_rows+1,2,subplot_num);
        imagesc(squeeze(CenteredHistogramMotor(k,:,:)));
        line([9 9],[0.5 numel(ZonesToUse)+0.5],'color','r');
        line([13 13],[0.5 numel(ZonesToUse)+0.5],'color','r');
        set(gca,'YTick', [], 'XTick', []);
    end
    
end

end