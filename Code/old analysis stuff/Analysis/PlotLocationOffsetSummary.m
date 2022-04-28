%Plotting offset perturbation summary
% AllResults(sessionincrement).Results = Results;
% Results.(mytag).ResponseLatency
% Results.(mytag).LeverVals
% Results.(mytag).SniffCounts


foo = colormap(brewermap([11],'RdBu'));
mycolors = foo([2 end-1],:);
mytag = ['B'; 'A'];

for i = 1:size(AllResults,2)
    for j = 1:2
        x_idx = i + (j-1)/4; 
%         subplot(1,4,1);
%         plot(x_idx,AllResults(i).Results.(char(mytag(j))).ResponseLatency,...
%             'o','MarkerFacecolor',mycolors(j,:),'MarkerEdgecolor','none');
        ReactionTime(i,j,1) = mean(AllResults(i).Results.(char(mytag(j))).ResponseLatency,'omitnan');
        ReactionTime(i,j,2) = std(AllResults(i).Results.(char(mytag(j))).ResponseLatency,'omitnan');
%         subplot(1,4,2);
%         plot(x_idx,AllResults(i).Results.(char(mytag(j))).LeverVals,'o',...
%             'MarkerFacecolor',mycolors(j,:),'MarkerEdgecolor','none');
        if j == 1
            SuccessRate(i,j) = numel(find(AllResults(i).Results.(char(mytag(j))).LeverVals<2.5));
            TrialCounts(i,j) = numel(AllResults(i).Results.(char(mytag(j))).LeverVals);
        else
            SuccessRate(i,j) = numel(find(AllResults(i).Results.(char(mytag(j))).LeverVals>2.5));
            TrialCounts(i,j) = numel(AllResults(i).Results.(char(mytag(j))).LeverVals);
        end
%         subplot(1,4,4);
%         plot(x_idx,AllResults(i).Results.(char(mytag(j))).SniffCounts,...
%             'o','MarkerFacecolor',mycolors(j,:),'MarkerEdgecolor','none');
        SniffTotal(i,j,1) = mean(AllResults(i).Results.(char(mytag(j))).SniffCounts,'omitnan');
        SniffTotal(i,j,2) = std(AllResults(i).Results.(char(mytag(j))).SniffCounts,'omitnan');
    end
    SuccessRate(i,3) = (SuccessRate(i,1) + SuccessRate(i,2))/(TrialCounts(i,1) + TrialCounts(i,2));
    SuccessRate(i,1) = SuccessRate(i,1)/TrialCounts(i,1);
    SuccessRate(i,2) = SuccessRate(i,2)/TrialCounts(i,2);
end

for j = 1:2
    subplot(1,3,1); hold on
    errorbar(1:i,squeeze(ReactionTime(:,j,1)),squeeze(ReactionTime(:,j,2)),'color',mycolors(j,:));
    plot(1:i,squeeze(ReactionTime(:,j,1)),'o','MarkerFacecolor',mycolors(j,:),'MarkerEdgecolor','none');
    set(gca,'XLim',[0 i+1],'YLim',[0 2000],'TickDir','out');
    subplot(1,3,2); hold on
    plot(1:i,SuccessRate(:,3),'-k');
    plot(1:i,SuccessRate(:,3),'ok','MarkerFacecolor','k');
    set(gca,'XLim',[0 i+1],'YLim',[0 1.1],'TickDir','out');
    subplot(1,3,3); hold on
    errorbar(1:i,squeeze(SniffTotal(:,j,1)),squeeze(SniffTotal(:,j,2)),'color',mycolors(j,:));
    plot(1:i,squeeze(SniffTotal(:,j,1)),'o','MarkerFacecolor',mycolors(j,:),'MarkerEdgecolor','none');
    set(gca,'XLim',[0 i+1],'YLim',[0 10],'TickDir','out');
end
set(gcf,'Position',[1 395 1280 310]);
set(gcf,'renderer','Painters');
print -depsc -tiff -r300 -painters N8_location_offset_summary.eps

% subplot(1,4,2); hold on
% subplot(1,4,3); hold on
% subplot(1,4,4); hold on

% subplot(1,4,3);
% b = bar(1:i,SuccessRate,'EdgeColor','none','FaceColor','flat');
% for k = 1:j
%     b(k).CData = mycolors(k,:);
% end
% b(3).CData = 0*mycolors(k,:);