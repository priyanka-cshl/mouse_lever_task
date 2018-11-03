DataPath = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/N4/processed';
cd (DataPath)
AllSessions = dir(DataPath);
sessioncount = 0;

% plot stay times and successrates
LearningCurve = 1;

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
LocationOffsetTrials = 0;
feedbackoffset = 200;

% GainPerturbation Trials
GainPerturbationTrials = 0;

% Halt Trials
HaltTrials = 0;

% Halt Trials
PauseTrials = 0;

if LearningCurve
    figure;
    subplot(3,1,1); hold on % maximum stay in target zone
    set(gca,'TickDir','out');
    subplot(3,1,2); hold on % total stay in target zone
    set(gca,'TickDir','out');
    subplot(3,1,3); hold on % trials
    set(gca,'TickDir','out');
end

sessionincrement = 0;

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
                AllSessions(i).name
                idx = find(TrajectoryStats(:,7)==2);
                numel(idx)
                
                if numel(idx)>=5
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
        end
        
        if NoOdorTrials && ~strcmp(AllSessions(i).name,'N8_20180930_r0_processed.mat')
            if find(TrajectoryStats(:,7)==3)
                idx = find(TrajectoryStats(:,7)==3);
                AllSessions(i).name
                numel(idx)
                
                if numel(idx)>=5
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
        end
        
        if LocationOffsetTrials && any(find(TrajectoryStats(:,7)==6))
            LocationOffsetPerturbation;
            if ~isempty(Results)
                sessionincrement = sessionincrement + 1;
                AllResults(sessionincrement).Name = AllSessions(i).name;
                AllResults(sessionincrement).Results = Results;
            end
        end
        
        if HaltTrials && any(find(TrajectoryStats(:,7)==9))
            perturbationID = 9;
            FeedbackPausePerturbation;
        end
        
        if PauseTrials && any(find(TrajectoryStats(:,7)==10))
            perturbationID = 10;
            FeedbackPausePerturbation;
        end
        
        if GainPerturbationTrials && any(find(TrajectoryStats(:,7)==8))
            perturbationID = 8;
            GainChangePerturbation;
            if ~isempty(Results)
                sessionincrement = sessionincrement + 1;
                AllResults(sessionincrement).Name = AllSessions(i).name;
                AllResults(sessionincrement).Results = Results;
            end
        end
    end
    
end

if FakeZoneControls
    figure('Name',AllSessions(i).name);
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
    
    set(gcf,'Position',[360   250   536   448]);
    set(gcf,'renderer','Painters');
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
    
    set(gcf,'Position',[360   250   536   448]);
        set(gcf,'renderer','Painters');
end