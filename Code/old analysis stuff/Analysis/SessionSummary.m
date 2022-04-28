function [numtrials] = SessionSummary(TrialInfo,ZonesToUse,TargetZones,ToPlot)
if nargin<3
    ToPlot = 0;
end

% for perturbations
myfakezone = cell2mat(cellfun(@(x) max([x; 0]), TrialInfo.FakeZone, 'UniformOutput', false))';

%% Rolling average success rate

    % rolling average success rate
    
    % size of running average window
    mywindow = 10; % in counts of trials
    rate = [];
    mytextlabel = [];

    for i = mywindow:size(TrialInfo.Success,1)
        rate = [rate; sum(TrialInfo.Success(i-mywindow+1:i))/mywindow];
    end
    % Zonewise success rate
    for Z = 1:numel(ZonesToUse)
        ZoneTrials = find(TrialInfo.TargetZoneType==ZonesToUse(Z));
        numtrials(Z,1) = numel(intersect(ZoneTrials,find(TrialInfo.Success==1)));        
        numtrials(Z,2) = numel(ZoneTrials) - numtrials(Z,1);
        mytextlabel{Z} = [num2str(numtrials(Z,1)),'/',num2str(numel(ZoneTrials))] ;

        if ~isempty(find(myfakezone))
            % perturbations - grouped by 'sensory target zones'
            perturbed = intersect(ZoneTrials,find(myfakezone));
            if ~isempty(perturbed)
                perturbtrials(Z,1) = numel(intersect(perturbed, find(TrialInfo.Success==1)));
                perturbtrials(Z,2) = numel(perturbed) - perturbtrials(Z,1);
            end
            
            % perturbations - grouped by 'fake target zones'
            perturbed = find(myfakezone==ZonesToUse(Z));
            if ~isempty(perturbed)
                perturbtrials(Z,3) = numel(intersect(perturbed, find(TrialInfo.Success==1)));
                perturbtrials(Z,4) = numel(perturbed) - perturbtrials(Z,3);
            end
            myPtextlabel{Z} = [num2str(perturbtrials(Z,3)),'/',num2str(numel(perturbed))] ;
        end
        
    end
    
    if ToPlot
        figure; 
        subplot(2,3,[1,2,3]); plot(rate);
        myplot = subplot(2,3,4); % success rate
        mybar = barh(mean(TargetZones(ZonesToUse,1:2),2),...
            numtrials,'stacked');
        mybar(1).FaceColor = 'g';
        mybar(2).FaceColor = 'r';
        % labels - no. of trials
        text(sum(numtrials,2)+0.1,mean(TargetZones(ZonesToUse,1:2),2), mytextlabel);
        myplot.Title.String = [num2str(sum(numtrials(:,1))),'/',num2str(sum(numtrials(:)))];
        
        if ~isempty(find(myfakezone))
            subplot(2,3,5); % perturbation successes
            mybar = barh(mean(TargetZones(ZonesToUse,1:2),2),...
                perturbtrials(:,1:2),'stacked');
            mybar(1).EdgeColor = 'g';
            mybar(1).LineWidth = 2;
            mybar(1).FaceColor = 'none';
            mybar(2).EdgeColor = 'r';
            mybar(2).LineWidth = 2;
            mybar(2).FaceColor = 'none';
            
            subplot(2,3,6); % perturbation successes
            mybar = barh(mean(TargetZones(ZonesToUse,1:2),2),...
                perturbtrials(:,3:4),'stacked');
            mybar(1).EdgeColor = 'g';
            mybar(1).LineWidth = 2;
            mybar(1).FaceColor = 'none';
            mybar(2).EdgeColor = 'r';
            mybar(2).LineWidth = 2;
            mybar(2).FaceColor = 'none';
            text(sum(perturbtrials(:,3:4),2)+0.1,mean(TargetZones(ZonesToUse,1:2),2), myPtextlabel);
            
        end
    end
end