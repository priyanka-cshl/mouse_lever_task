function [] = LearningCurve(DataFile, subplotcol)
    
% StayTimes
    % for every trial - time of entry and exit and stay
     % num of rows in the cell array = no. of entries
     % sum of col 3 = total time stayed (in indices)
% TrialStats
    % FractionSpent = sum of col3 from staytimes/triallength
    % MaxStay - max of col3 (in indices)
    % MaxFractionStay - max of col3 in proportional trial time

[~,Structname] = fileparts(DataFile);
MyData = load (fullfile('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/',DataFile));
AllSessions = fieldnames(MyData.(Structname));
for i = 1:size(AllSessions,1) % every session
    Temp = MyData.(Structname).(char(AllSessions(i)));
    MeanMaxStay = [];
    MeanTotalStay = [];
    for Z = 1:numel(Temp.ZonesToUse) % every Zone Type
        trialIDs = cell2mat(Temp.Trajectories.TrialIDs.All(Z));
        MeanMaxStay = [MeanMaxStay; Temp.TrialStats.MaxStay(trialIDs,Z)];
        if any(trialIDs>size(Temp.TrialStats.TotalStay,1))
            trialIDs(find(trialIDs>size(Temp.TrialStats.TotalStay,1)),:) = [];
        end
        MeanTotalStay = [MeanTotalStay; Temp.TrialStats.TotalStay(trialIDs,Z)];
    end
    
    for whichplot = 1:2
        if whichplot == 1
            foo = 2*MeanMaxStay; % convert from indices to time in ms given sample rate of 500 Hz
        else
            foo = 2*MeanTotalStay;
        end
        subplot(3,3,3*(whichplot-1)+subplotcol); hold on; 
        % plot all values as grey dots
        plot(i,foo,'o',...
            'MarkerFaceColor',0.6*[1 1 1],...
            'MarkerSize',3,...
            'MarkerEdgeColor','none');
        % plot sd
        errorbar(i,mean(foo),std(foo),'k','Linewidth',1);
        % plot mean
        plot(i,mean(foo),'o',...
            'MarkerFaceColor','k',...
            'MarkerEdgeColor','k');
        if subplotcol == 1
            if whichplot == 1
                set(gca,'YLim',[0 800],'YTick', [0 250 500 750]);
            else
                set(gca,'YLim',[0 1750],'YTick', [0 500 1000 1500]);
            end
        else
            if whichplot == 1
                set(gca,'YLim',[0 800],'YTick', []);
            else
                set(gca,'YLim',[0 1750],'YTick',[]);
            end
        end
        set(gca,'XLim',[0.5 20.5],'TickDir','out','XTick',[],'Fontsize',14,'FontWeight','b');
    end
    subplot(3,3,6+subplotcol); hold on; % success rate
    myfakezone = cell2mat(cellfun(@(x) max([x; 0]), Temp.TrialInfo.FakeZone, 'UniformOutput', false))';
    successrate = numel(intersect(find(Temp.TrialInfo.Success),find(~myfakezone)))/numel(find(~myfakezone));
    plot(i,successrate,'o','MarkerFaceColor','k',...
            'MarkerEdgeColor','k');
    set(gca,'XLim',[0.5 20.5],'TickDir','out','Fontsize',14,'FontWeight','b');
    if subplotcol == 1
        set(gca,'YLim',[0 1],'YTick', [0 0.5 1]);
    else
        set(gca,'YLim',[0 1],'YTick',[]);
    end
end
    
end