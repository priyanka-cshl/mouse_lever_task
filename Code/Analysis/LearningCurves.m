function [] = LearningCurves()

mycolors = colormap(brewermap([6],'Spectral'));

for M = 1:6
    MouseName = ['N',num2str(M+2)]
    MyColor = mycolors(M,:);
    
    DataPath = ['/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/',MouseName,'/processed'];
    cd (DataPath)
    AllSessions = dir(DataPath);
    
    StayTimes = [];
    StayProportions = [];
    NumTrials = [];
    SuccessRate = [];
    
    sessioncount = 0;
    MaxTimeSpent = [];
    ProportionTimeSpent = [];
    TrialCounts = [];
    mydate = '';
    
    for i = 1:size(AllSessions,1)
        if ~isempty(strfind(AllSessions(i).name,'.mat')) &&...
                isempty(strfind(AllSessions(i).name,'concatenated'))
            
            load(AllSessions(i).name, 'TrajectoryStats');
            % only use unperturbed trials
            idx = find(TrajectoryStats(:,7)==0);
            % Trajectory Stats
            % maxstay totalstay entrylatency attempts
            % rewardlatency TargetZone Perturbation PerturbationOffsetStart
            
            if numel(idx)>150
                if ~isempty(strfind(AllSessions(i).name,mydate)) || (sessioncount==0)
                    % don't clear old data
                    if sessioncount == 0
                        sessioncount = sessioncount + 1;
                        % club together sessions
                        mydate = AllSessions(i).name(strfind(AllSessions(i).name,'2018')+(0:1:7));
                    end
                else
                    %if sessioncount > 1
                    % compile what you have already
                    StayTimes(sessioncount,:) = [nanmean(MaxTimeSpent) std(MaxTimeSpent,'omitnan')];
                    StayProportions(sessioncount,:) = [nanmean(ProportionTimeSpent) std(ProportionTimeSpent,'omitnan')];
                    NumTrials(sessioncount,:) = [sum(TrialCounts(:,1)) sum(TrialCounts(:,2))];
                    SuccessRate(sessioncount,1) = (NumTrials(sessioncount,1)-NumTrials(sessioncount,2))/NumTrials(sessioncount,1);
                    
                    
                    % get the new data
                    sessioncount = sessioncount + 1;
                    % club together sessions
                    mydate = AllSessions(i).name(strfind(AllSessions(i).name,'2018')+(0:1:7));
                    MaxTimeSpent = [];
                    ProportionTimeSpent = [];
                    TrialCounts = [];
                    
                    %end
                end
                MaxTimeSpent = [MaxTimeSpent; 2*TrajectoryStats(idx,1)];
                ProportionTimeSpent = [ProportionTimeSpent; 2*TrajectoryStats(idx,2)];
                TrialCounts = [TrialCounts; [numel(idx)] numel(find(isnan(TrajectoryStats(idx,5))))];
            end
        end
    end
    
    % add the last one
    StayTimes(sessioncount,:) = [nanmean(MaxTimeSpent) std(MaxTimeSpent,'omitnan')];
    StayProportions(sessioncount,:) = [nanmean(ProportionTimeSpent) std(ProportionTimeSpent,'omitnan')];
    NumTrials(sessioncount,:) = [sum(TrialCounts(:,1)) sum(TrialCounts(:,2))];
    SuccessRate(sessioncount,1) = (NumTrials(sessioncount,1)-NumTrials(sessioncount,2))/NumTrials(sessioncount,1);
    
    % plot
    %figure('Name',MouseName);
    
    subplot(3,1,1);
    MyShadedErrorBar(1:sessioncount,StayTimes(:,1)',StayTimes(:,2)',...
        MyColor,[],0.25);
    %errorbar(1:sessioncount,StayTimes(:,1)',StayTimes(:,2)','color',MyColor);
    hold on;
    plot(1:sessioncount,StayTimes(:,1),'color',MyColor,'LineWidth',2);
    
    if M == 6
        line([0 sessioncount+1],[250 250],'LineStyle',':','color','r');
        set(gca,'XLim',[0 sessioncount+1],'YLim',[-10 510],'TickDir','out');
        set(gca,'XTick',[0:5:sessioncount+1],'YTick',[0:250:500]);
    end
    
    % subplot(4,1,2);
    % MyShadedErrorBar(1:sessioncount,StayProportions(:,1)',StayProportions(:,2)',...
    %     'k',[],0.5);
    % hold on;
    % plot(1:sessioncount,StayProportions(:,1),'k','LineWidth',1);
    % set(gca,'XLim',[0 sessioncount+1],'YLim',[-0.1 2],'TickDir','out');
    % set(gca,'XTick',[0:5:sessioncount+1],'YTick',[0:0.5:1.5]);
    % %line([0 sessioncount+1],[250 250],':','color','r');
    
    subplot(3,1,2);
    plot(1:sessioncount,SuccessRate(:,1),'color',MyColor,'LineWidth',2);
    hold on;
    %plot(1:sessioncount,SuccessRate(:,1),'o','MarkerFaceColor',MyColor,'MarkerEdgeColor','none');
    if M == 6
        line([0 sessioncount+1],[0.8 0.8],'LineStyle',':','color','r');
        set(gca,'XLim',[0 sessioncount+1],'YLim',[0.4 1.1],'TickDir','out');
        set(gca,'XTick',[0:5:sessioncount+1],'YTick',[0.5 1]);
    end
    
    subplot(3,1,3);
    plot(1:sessioncount,NumTrials(:,1),'color',MyColor,'LineWidth',2);
    hold on;
    %plot(1:sessioncount,NumTrials(:,1),'o','MarkerFaceColor',MyColor,'MarkerEdgeColor','none');
    if M == 6
        set(gca,'XLim',[0 sessioncount+1],'YLim',[0 1000],'TickDir','out');
        set(gca,'XTick',[0:5:sessioncount+1],'YTick',[0:250:1000]);
        line([0 sessioncount+1],[250 250],'LineStyle',':','color','r');
        line([0 sessioncount+1],[500 500],'LineStyle',':','color','r');
    end
    
end

set(gcf,'Position',[360 190 464 508]);
set(gcf,'renderer','Painters');
cd '/Users/Priyanka/Desktop/LABWORK_II/conferences:meetings/SFN2018/figures'

