DataPath = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/N8/processed';
cd (DataPath)
AllSessions = dir(DataPath);

SessionName = 'N8_20180924_r0_processed.mat';
load(SessionName, 'Trajectories');
load(SessionName, 'TrajectoryStats');

TargetZones(:,2) = 1:0.25:3.75;
TargetZones(:,1) = TargetZones(:,2) + 0.3;
TargetZones(:,3) = TargetZones(:,2) - 0.3;

figure;
% for each zone
for i = 1:12 

    %% successful and failed trials
    idx = find((TrajectoryStats(:,6)==i)&... % target zone
        (TrajectoryStats(:,8)==0)); % not perturbed
    
        %(~isnan(TrajectoryStats(:,5)))&... % rewarded
        
    if ~isempty(idx)
        MyLever = Trajectories.Lever(idx,:);
        
        subplot(2,12,i);
        hold on;
        title(num2str(numel(idx)));
        
        % plot all TargetZones
        xlims = [0 1250];
        ylims = [TargetZones(i,[1 3]) TargetZones(i,[3 1])];
        fill( [xlims(1) xlims(1) xlims(2) xlims(2)], ylims,...
            [1 1 0],...
            'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % plot the average trajectory
        MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
            std(MyLever,'omitnan')/sqrt(numel(idx)),...
            'k',[],0.5);
        
        % Ticks and axis limits
        set(gca,'XTick',[],'YLim',[0 5],'XLim',xlims,'Fontsize',12,'FontWeight','b','Box','on','LineWidth',1);
        
        if i == 1
            set(gca,'YTick',[0 5]);
        else
            set(gca,'YTick',[]);
        end
    end
    
%     %% failed trials
%     idx = find((TrajectoryStats(:,6)==i)&... % target zone
%                (isnan(TrajectoryStats(:,5)))&... % not rewarded
%                 (TrajectoryStats(:,8)==0)); % not perturbed
%     
%     if ~isempty(idx)        
%         MyLever = Trajectories.Lever(idx,:);
%         
%         subplot(3,12,i+12);
%         hold on;
%         title(num2str(numel(idx)));
%         
%         % plot all TargetZones
%         fill( [xlims(1) xlims(1) xlims(2) xlims(2)], ylims,...
%             [1 1 0],...
%             'FaceAlpha', 0.2, 'EdgeColor', 'none');
%         
%         % plot the average trajectory
%         MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
%             std(MyLever,'omitnan')/sqrt(numel(idx)),...
%             'k',[],0.5);
%         
%         % Ticks and axis limits
%         set(gca,'XTick',[],'YLim',[0 5],'XLim',xlims,'Fontsize',12,'FontWeight','b','Box','on','LineWidth',1);
%         
%         if i == 1
%             set(gca,'YTick',[0 5]);
%         else
%             set(gca,'YTick',[]);
%         end
%     end
    
    %% perturbed trials
    idx = find((TrajectoryStats(:,6)==i)&... % target zone
                (TrajectoryStats(:,8)>0)); % perturbed
    
    if ~isempty(idx)        
        MyLever = Trajectories.Lever(idx,:);
        
        subplot(2,12,i+12);
        hold on;
        title(num2str(numel(idx)));
        
        % plot all TargetZones
        fill( [xlims(1) xlims(1) xlims(2) xlims(2)], ylims,...
            [1 1 0],...
            'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % plot the average trajectory
        MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
            std(MyLever,'omitnan')/sqrt(numel(idx)),...
            'k',[],0.5);
        
        % Ticks and axis limits
        set(gca,'YLim',[0 5],'XLim',xlims,'Fontsize',12,'FontWeight','b','Box','on','LineWidth',1);
        
        if i == 1
            set(gca,'YTick',[0 5],'XTick',[0 1250],'XTickLabel',{'0', '2.5s'});
        else
            set(gca,'YTick',[],'XTick',[0 1250],'XTickLabel',{'0', '2.5s'});
        end
        
    end

    
end

set(gcf,'Position',[1 348 1280 350]);
set(gcf,'renderer','Painters');
cd '/Users/Priyanka/Desktop/LABWORK_II/conferences:meetings/SFN2018/figures'
