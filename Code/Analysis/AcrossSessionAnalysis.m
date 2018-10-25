DataPath = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/N5/processed';
cd (DataPath)
AllSessions = dir(DataPath);
sessioncount = 0;

% plot stay times and successrates
LearningCurve = 0;

% FakeZoneTrials
FakeZoneControls = 0;
if FakeZoneControls
    DistanceAxis = [-2.75:0.25:2.75];
    MyDist = [];
    [~,targetzones] = WhichZones(0,'');
    SuccessRates = [];
    TrialCounts = [];
end

% NoOdorTrials
NoOdorTrials = 0;
if NoOdorTrials
    DistanceAxis = [-2.75:0.25:2.75];
    MyDist = [];
    [~,targetzones] = WhichZones(0,'');
    SuccessRates = [];
    TrialCounts = [];
end

% LocationOffsetTrials
LocationOffsetTrials = 1;    
feedbackoffset = 200;

if LearningCurve
    figure;
    subplot(3,1,1); hold on % maximum stay in target zone
    set(gca,'TickDir','out');
    subplot(3,1,2); hold on % total stay in target zone
    set(gca,'TickDir','out');
    subplot(3,1,3); hold on % trials
    set(gca,'TickDir','out');
end

for i = 1:size(AllSessions,1)
    if strfind(AllSessions(i).name,'.mat')
        sessioncount = sessioncount + 1;
        
        % Trajectory Stats
        % maxstay totalstay entrylatency attempts 
        % rewardlatency TargetZone Perturbation PerturbationOffsetStart
        
        
        load(AllSessions(i).name, 'TrajectoryStats');
        
        
        if LearningCurve
            % plot distribution of max stays
            subplot(3,1,1);
            temp = 2*TrajectoryStats(:,1);
            temp(find(TrajectoryStats(:,7)),:) = [];
            violin(temp,'x',[sessioncount Inf],'plotlegend',0, 'facecolor',[0.6 0.6 0.6],'edgecolor','none');
            %plot(sessioncount,2*TrajectoryStats(:,1),'.r');
            %errorbar(sessioncount,mean(2*TrajectoryStats(:,1)),std(2*TrajectoryStats(:,1)));
            
            subplot(3,1,2);
            temp = 2*TrajectoryStats(:,2);
            temp(find(TrajectoryStats(:,7)),:) = [];
            violin(temp,'x',[sessioncount Inf],'plotlegend',0,'facecolor',[0.6 0.6 0.6],'edgecolor','none');
            %errorbar(sessioncount,mean(2*TrajectoryStats(:,2)),std(2*TrajectoryStats(:,2)));
            
            subplot(3,1,3);
            bar(sessioncount,numel(temp),'facecolor','k','edgecolor','none');
            temp = TrajectoryStats(:,5);
            temp(find(TrajectoryStats(:,7)),:) = [];
            bar(sessioncount,numel(find(isnan(temp))),'facecolor','r','edgecolor','none');
        end
        
        if FakeZoneControls  
           if find(TrajectoryStats(:,7)==2)
               idx = find(TrajectoryStats(:,7)==2);
               load(AllSessions(i).name, 'ZoneStays');
               ZoneWeights = NaN*ones(numel(DistanceAxis),numel(idx));
               for j = 1:numel(idx)
                    whichfakezone = WhichZones(TrajectoryStats(idx(j),8),'low');
                    whichtargetzone = TrajectoryStats(idx(j),6);
                    temp = ZoneStays(idx(j),:);
                    for z = 1:12
                        zonedistance = targetzones(z) - targetzones(whichtargetzone);
                        ZoneWeights(find(DistanceAxis==zonedistance),j) = temp(z)/sum(temp);
                    end
                    fakezonesuccess(j) = ~isnan(TrajectoryStats(idx(j),5));
               end
               MyDist = horzcat(MyDist, nanmean(ZoneWeights,2));
               targetzonesuccess = numel(find((~isnan(TrajectoryStats(:,5)))&(TrajectoryStats(:,7)==0)));
               targetzonesuccess = targetzonesuccess/numel(find(TrajectoryStats(:,7)==0));
               SuccessRates = vertcat(SuccessRates, ...
                            [ targetzonesuccess numel(find(fakezonesuccess))/numel(idx)]);
               TrialCounts = vertcat(TrialCounts, [numel(find(TrajectoryStats(:,7)==0)) numel(idx)]);
           end
        end

        if NoOdorTrials && ~strcmp(AllSessions(i).name,'N8_20180930_r0_processed.mat')
            if find(TrajectoryStats(:,7)==3)
                idx = find(TrajectoryStats(:,7)==3);
                load(AllSessions(i).name, 'ZoneStays');
                ZoneWeights = NaN*ones(numel(DistanceAxis),numel(idx));
                noodorsuccess = [];
                for j = 1:numel(idx)
                    whichtargetzone = TrajectoryStats(idx(j),6);
                    temp = ZoneStays(idx(j),:);
                    for z = 1:12
                        zonedistance = targetzones(z) - targetzones(whichtargetzone);
                        ZoneWeights(find(DistanceAxis==zonedistance),j) = temp(z)/sum(temp);
                    end
                    noodorsuccess(j) = ~isnan(TrajectoryStats(idx(j),5));
                end
                MyDist = horzcat(MyDist, nanmean(ZoneWeights,2));
                targetzonesuccess = numel(find((~isnan(TrajectoryStats(:,5)))&(TrajectoryStats(:,7)==0)));
                targetzonesuccess = targetzonesuccess/numel(find(TrajectoryStats(:,7)==0));
                
                TrialCounts = vertcat(TrialCounts, [numel(find(TrajectoryStats(:,7)==0)) numel(idx)]);

                % bootstrapped success rate distribution
                f = find(TrajectoryStats(:,7)==0);
                [BootStrapDist] = BootStrappedSuccessRates(TrajectoryStats(f,5:6),TrajectoryStats(idx,6));
                SuccessRates = vertcat(SuccessRates, ...
                    [ BootStrapDist targetzonesuccess numel(find(noodorsuccess))/numel(idx)]);
            end
        end
        
        if LocationOffsetTrials
            if find(TrajectoryStats(:,7)==6)
                idxUp = find((TrajectoryStats(:,7)==6)&(TrajectoryStats(:,8)>121));
                idxDown = find((TrajectoryStats(:,7)==6)&(TrajectoryStats(:,8)<121));
                
                if (numel(idxUp)+numel(idxDown))>6
                    figure('Name',AllSessions(i).name);
                    AverageTraceUp = [];
                    AverageTraceDown = [];
                    
                    load(AllSessions(i).name, 'Trajectories');
                    MyLeverUp = Trajectories.Lever(idxUp,:);
                    MyLeverDown = Trajectories.Lever(idxDown,:);
                    lengthUp = 0;
                    lengthDown = 0;
                    
                    subplot(2,1,1);
                    for k = 1:numel(idxUp)
                        t1 = TrajectoryStats(idxUp(k),9) - feedbackoffset;
                        if t1>=0
                            t2 = find(isnan(MyLeverUp(k,t1+1:end)),1);
                            mytrace = [MyLeverUp(k,t1+1:end) NaN*ones(1,t1)];
                        else
                            t2 = -t1+find(isnan(MyLeverUp(k,1:end)),1);
                            mytrace = [NaN*ones(1,-t1) MyLeverUp(k,1:end) NaN*ones(1,t1)];
                        end
                        plot((1:length(mytrace))-feedbackoffset,mytrace,'r'); hold on
                        AverageTraceUp(k,1:length(mytrace)) = mytrace;
                        lengthUp = max(lengthUp,t2);
                    end
                    for k = 1:numel(idxDown)
                        t1 = TrajectoryStats(idxDown(k),9) - feedbackoffset;
                        t2 = find(isnan(MyLeverDown(k,t1+1:end)),1);
                        mytrace = [MyLeverDown(k,t1+1:end) NaN*ones(1,t1)];
                        plot((1:length(mytrace))-feedbackoffset,mytrace,'b'); hold on
                        AverageTraceDown(k,1:length(mytrace)) = mytrace;
                        lengthDown = max(lengthDown,t2);
                    end
                    line([0 0],[0 5],'color','k','LineStyle',':','Linewidth',1)
                    line([-feedbackoffset size(AverageTraceDown,2)-feedbackoffset],[2.5 2.5],'color','k','LineStyle','--','Linewidth',1)
                    set(gca,'XLim',[-feedbackoffset max(lengthUp, lengthDown)],'YLim',[0 5]);
                    
                    subplot(2,1,2);
                    plot((1:size(AverageTraceUp,2))-feedbackoffset,nanmedian(AverageTraceUp,1),'r');
                    hold on
                    plot((1:size(AverageTraceDown,2))-feedbackoffset,nanmedian(AverageTraceDown,1),'b');
                    line([0 0],[0 5],'color','k','LineStyle',':','Linewidth',1)
                    line([-feedbackoffset size(AverageTraceDown,2)-feedbackoffset],[2.5 2.5],'color','k','LineStyle','--','Linewidth',1)
                    set(gca,'XLim',[-feedbackoffset max(lengthUp, lengthDown)],'YLim',[0 5]);
                end
                
            end
        end
    end
end

if FakeZoneControls
    figure;
    for i = 1:size(SuccessRates,1)
        subplot(2,1,1); hold on
        plot(i-0.25,SuccessRates(i,1),'ok','MarkerFaceColor','k','MarkerSize',4);
        plot(i+0.25,  SuccessRates(i,2),'or','MarkerFaceColor','r','MarkerSize',4);
        line(i+[-0.25 0.25],SuccessRates(i,:),'color','k');
        
        subplot(2,1,2); hold on
        temp = MyDist(:,i);
        x = MyDist(~isnan(temp),i)/max(MyDist(~isnan(temp),i));
        y = DistanceAxis(~isnan(temp))';
        x = [0; x; 0];
        y = [y(1); y; y(end)];
        
        pgon = polyshape(i+ 0.8*x,y);
        h = plot(pgon,'FaceColor',[0.6 0.6 0.6],'EdgeColor','none');
    end    
    
    subplot(2,1,1);
    set(gca,'XLim',[0 i+1], 'XTick',[1:1:i],'TickDir','out','YTick',[0 0.5 1]);
    subplot(2,1,2);
    set(gca,'XLim',[0 i+1],'XTick',[1:1:i],'TickDir','out');
    line([0 i+1],[0 0],'color', 'k', 'LineStyle',':','Linewidth',1);
end

if NoOdorTrials
    figure;
    for i = 1:size(SuccessRates,1)
        subplot(2,1,1); hold on
        %plot(i-0.25,SuccessRates(i,1),'ok','MarkerFaceColor','k','MarkerSize',4);
        plot(i-0.25+(randperm(20,20)/80),...
            SuccessRates(i,1:20),'ok','MarkerSize',3);
        plot(i-0.125,SuccessRates(i,21),'ok','MarkerFaceColor','k','MarkerSize',6);
        plot(i+0.25,  SuccessRates(i,end),'or','MarkerFaceColor','r','MarkerSize',4);
        line(i+[-0.125 0.25],SuccessRates(i,end-1:end),'color','k');
        
        subplot(2,1,2); hold on
        temp = MyDist(:,i);
        x = MyDist(~isnan(temp),i)/max(MyDist(~isnan(temp),i));
        y = DistanceAxis(~isnan(temp))';
        x = [0; x; 0];
        y = [y(1); y; y(end)];
        pgon = polyshape(i -0.25 + 0.8*x,y);
        h = plot(pgon,'FaceColor',[0.6 0.6 0.6],'EdgeColor','none');
        
    end    
    
    subplot(2,1,1);
    set(gca,'XLim',[0 i+1], 'XTick',[1:1:i],'TickDir','out','YLim',[-0.1 1.1], 'YTick',[0 0.5 1]);
    subplot(2,1,2);
    set(gca,'XLim',[0 i+1],'XTick',[1:1:i],'TickDir','out');
    line([0 i+1],[0 0],'color', 'k', 'LineStyle',':','Linewidth',1);
end