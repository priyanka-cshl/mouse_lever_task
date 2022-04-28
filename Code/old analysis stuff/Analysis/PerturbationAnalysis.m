function [] = PerturbationAnalysis(DataFile, subplotcol)
    
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
    % logical vector of whether a trial was perturbed or not
    myfakezone = cell2mat(cellfun(@(x) max([x; 0]), Temp.TrialInfo.FakeZone, 'UniformOutput', false))';
    % success rate in unperturbed trials
    num_trials_control = numel(find(~myfakezone));
    successrate_control = numel(intersect(find(Temp.TrialInfo.Success),find(~myfakezone)))/numel(find(~myfakezone));
    % success rate in perturbed trials
    num_trials_perturb = numel(find(myfakezone));
    successrate_perturb = numel(intersect(find(Temp.TrialInfo.Success),find(myfakezone)))/numel(find(myfakezone));
    % success rate as a function of distance between fake and actual zone
    trialIDs = find(myfakezone);
    ZoneDistance = Temp.TargetZones(Temp.TrialInfo.TargetZoneType(trialIDs),2) - Temp.TargetZones(myfakezone(trialIDs),2);
    ZoneSuccess = Temp.TrialInfo.Success(trialIDs);
    
    % bin by distance
    j = 0;
    for r = -2.75:0.5:2.75
        j = j + 1;
        DistanceSuccessRate(j,i) = numel(intersect(find(ZoneDistance==r),find(ZoneSuccess)))/...
            numel(find(ZoneDistance==r));
    end
    j = 0;
    for r = 0:0.25:2.75
        j = j + 1;
        DistanceSuccessRateAbs(j,i) = numel(intersect(find(abs(ZoneDistance)==r),find(ZoneSuccess)))/...
            numel(find(abs(ZoneDistance)==r));
    end
    
    % PLOT
    % successrate of each session
    subplot(2,3,subplotcol); hold on;
    % plot control success rate values as black dot, perturb as red
    plot(1,successrate_control,'o','MarkerFaceColor',0.75*[1 1 1],'MarkerEdgeColor','k');
    plot(2,successrate_perturb,'o','MarkerFaceColor','r','MarkerEdgeColor','k');
    line([1 2],[successrate_control successrate_perturb],'color','k');
end
        
if subplotcol == 1
    set(gca,'YLim',[0 1],'YTick', [0 0.5 1]);
else
    set(gca,'YLim',[0 1],'YTick', []);
end
set(gca,'XLim',[0.5 2.5],'TickDir','out','XTick',[1 2],'XTickLabel',{'control', 'perturb'},...
    'XTickLabelRotation', 0, 'Fontsize',14,'FontWeight','b');

subplot(2,3,subplotcol+3); hold on;
MeanRate = Mean_NoNaNs(DistanceSuccessRateAbs,2);
errorbar(0:0.25:2.75,MeanRate(1,:),MeanRate(2,:));
plot(0:0.25:2.75,MeanRate(1,:),'o','MarkerFaceColor','k',...
     'MarkerEdgeColor','k');
set(gca,'XLim',[-0.25 3],'TickDir','out','XTick',[0:0.5:2.75],...
    'XTickLabel', {'0.0', '0.5', '1.0', '1.5', '2.0', '2.5'},...
     'XTickLabelRotation', 45, 'Fontsize',14,'FontWeight','b');
if subplotcol == 1
    set(gca,'YLim',[-0.5 1.5],'YTick', [0 0.5 1]);
else
    set(gca,'YLim',[-0.5 1.5],'YTick',[]);
end

end