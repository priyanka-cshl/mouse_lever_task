function [numtrials] = SessionStats(TrialInfo,Trajectories, ZonesToUse,TargetZones,ToPlot)
if nargin<4
    ToPlot = 0;
end
ZonesToUse = flipud(ZonesToUse); % to make sure the TFs are plotted from top to bottom

% for perturbations
myfakezone = cell2mat(cellfun(@(x) max([x; 0]), TrialInfo.FakeZone, 'UniformOutput', false))';

%% Rolling average success rate    
% size of running average window
mywindow = 10; % in counts of trials
rate = [];
mytextlabel = [];

% remove perturbed trials when considering successes and failures
SuccessScore = TrialInfo.Success;
SuccessScore(find(myfakezone>0),:) = [];
SessionSuccessRate = 100*round(numel(find(SuccessScore))/numel(SuccessScore),2);

for i = mywindow:numel(SuccessScore);
    rate(i,1) = sum(SuccessScore(i-mywindow+1:i))/mywindow;
end
% delete early bins
rate(1:mywindow-1,:) = [];

%% Zonewise success rate
for Z = 1:numel(ZonesToUse)
   ZoneTrials = cell2mat(Trajectories.TrialIDs.All(Z));
   
   numtrials(Z,1) = numel(cell2mat(Trajectories.TrialIDs.Successes(Z)));
   numtrials(Z,2) = numel(ZoneTrials) - numtrials(Z,1);
   mytextlabel{Z} = [num2str(numtrials(Z,1)),'/',num2str(numel(ZoneTrials))] ;
    
    if ~isempty(find(myfakezone))
        % perturbations - grouped by 'sensory target zones'
        perturbed = cell2mat(Trajectories.TrialIDs.Perturbed(Z));
        if ~isempty(perturbed)
            perturbtrials(Z,1) = numel(intersect(perturbed, find(TrialInfo.Success==1)));
            perturbtrials(Z,2) = numel(perturbed) - perturbtrials(Z,1);
        else
            perturbtrials(Z,1:2) = [0 0];
        end
        
        % perturbations - grouped by 'fake target zones'
        perturbed = cell2mat(Trajectories.TrialIDs.Fake(Z));
        if ~isempty(perturbed)
            perturbtrials(Z,3) = numel(intersect(perturbed, find(TrialInfo.Success==1)));
            perturbtrials(Z,4) = numel(perturbed) - perturbtrials(Z,3);
        else
            perturbtrials(Z,3:4) = [0 0];
        end
        myPtextlabel{Z} = [num2str(perturbtrials(Z,3)),'/',num2str(numel(perturbed))] ;
    end
    
end

%% plotting
num_cols = 1 + 2*~isempty(find(myfakezone));

if ToPlot
    figure;
    subplot(2,num_cols,1:max(1,num_cols-1)); 
    plot(rate);
    ax = gca;
    ax.Title.String = ['Average Success Rate = ', num2str(SessionSuccessRate), '%'];
    ax.Title.FontSize = 12;
    ax.YLim = [-0.1 1.1];
    ax.YTick = [0 0.5 1];
    set(gca,'TickDir','out','Fontsize',12,'FontWeight','b');
    
    myplot = subplot(2,num_cols,num_cols+1); % success rate
    mybar = barh(mean(TargetZones(ZonesToUse,1:3),2),...
        numtrials,'stacked');
    mybar(1).FaceColor = 'k';
    mybar(2).FaceColor = 'r';
    mybar(2).EdgeColor = 'r';
    % labels - no. of trials
    %text(sum(numtrials,2)+0.1,mean(TargetZones(ZonesToUse,1:3),2), mytextlabel);
    myplot.Title.String = [num2str(sum(numtrials(:,1))),' / ',num2str(sum(numtrials(:)))];
    set(gca,'TickDir','out','YTick',[],'Fontsize',12,'FontWeight','b');
    
    if ~isempty(find(myfakezone))
        subplot(2,num_cols,num_cols+2); % perturbation successes
        mybar = barh(mean(TargetZones(ZonesToUse,1:3),2),...
            perturbtrials(:,1:2),'stacked');
        mybar(1).FaceColor = 'k';
        mybar(2).FaceColor = 'r';
        mybar(2).EdgeColor = 'r';
%         mybar(1).EdgeColor = 'k';
%         mybar(1).LineWidth = 2;
%         mybar(1).FaceColor = 'none';
%         mybar(2).EdgeColor = 'r';
%         mybar(2).LineWidth = 2;
%         mybar(2).FaceColor = 'none';
        ax = gca;
        ax.Title.String = [num2str(sum(perturbtrials(:,1))),' / ',num2str(sum(perturbtrials(:,1))+sum(perturbtrials(:,2)))];
        set(gca,'TickDir','out','YTick',[],'Fontsize',12,'FontWeight','b');
        
        subplot(2,num_cols,num_cols+3); % perturbation successes
        mybar = barh(mean(TargetZones(ZonesToUse,1:3),2),...
            perturbtrials(:,3:4),'stacked');
        mybar(1).FaceColor = 'k';
        mybar(2).FaceColor = 'r';
        mybar(2).EdgeColor = 'r';
%         mybar(1).EdgeColor = 'k';
%         mybar(1).LineWidth = 2;
%         mybar(1).FaceColor = 'none';
%         mybar(2).EdgeColor = 'r';
%         mybar(2).LineWidth = 2;
%         mybar(2).FaceColor = 'none';
        %text(sum(perturbtrials(:,3:4),2)+0.1,mean(TargetZones(ZonesToUse,1:3),2), myPtextlabel);
        ax = gca;
        ax.Title.String = [num2str(sum(perturbtrials(:,3))),' / ',num2str(sum(perturbtrials(:,3))+sum(perturbtrials(:,4)))];
        set(gca,'TickDir','out','YTick',[],'Fontsize',12,'FontWeight','b');
    end
end
end