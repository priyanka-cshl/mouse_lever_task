function [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, WhichTargetCase, DoPlot)

if nargin < 5
    WhichTargetCase = 2;
end

%% initializations
global timewindow;
global MyFileName;

for z = 1:numel(ZonesToUse)
    Trajectories.(['Z',num2str(z)]).Traces = [];
    Trajectories.(['Z',num2str(z)]).Outcome = [];
    Trajectories.(['Z',num2str(z)]).ZoneType = [];
end

switch WhichTargetCase
    case 1
        TargetThreshold = TargetZones(:,1); % upper limit
    case 2
        TargetThreshold = mean(TargetZones(:,1:2),2); % mean
    case 3
        TargetThreshold = TargetZones(:,2); % lower limit
end
     
%% for each trial, analyze trajectory w.r.t. Zone entry for all valid zones
for t = 1:size(LeverTruncated,1) % every trial
    temp = [NaN+ones(1,timewindow), LeverTruncated(t,:), NaN+ones(1,timewindow)];
    for z = 1:numel(ZonesToUse)
        [MyTraces] = DetectTargetZoneCross(temp,TargetThreshold(z));
        if ~isempty(MyTraces)
            Trajectories.(['Z',num2str(z)]).Traces = [Trajectories.(['Z',num2str(z)]).Traces; MyTraces];
            %if TrialInfo.TargetZoneType(t) == ZonesToUse(z)
            Trajectories.(['Z',num2str(z)]).Outcome = [Trajectories.(['Z',num2str(z)]).Outcome; zeros(size(MyTraces,1),1) + TrialInfo.Success(t)];
            Trajectories.(['Z',num2str(z)]).ZoneType = [Trajectories.(['Z',num2str(z)]).ZoneType; zeros(size(MyTraces,1),1) + (find(ZonesToUse==TrialInfo.TargetZoneType(t)))];
            %end
        end
    end
end

%% Make plots
if DoPlot
    figure('Name',[char(MyFileName),'ZoneAligned']);
    for z = 1:numel(ZonesToUse)
        cmat = [0 0 0];
        cmat(z) = 1;
        subplot(3,numel(ZonesToUse),z); hold on;
        HighLim = TargetZones(z,1);
        LowLim = TargetZones(z,2);
        fill([-timewindow -timewindow timewindow timewindow], ...
            [LowLim HighLim HighLim LowLim],cmat/2,'FaceAlpha',0.1,'EdgeColor','none');
        
        for j = 1:3
            cmat = [0 0 0];
            cmat(j) = 1;
            f = find(Trajectories.(['Z',num2str(z)]).ZoneType==j);
            AverageTrajectories = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).Traces(f,:),1);
            shadedErrorBar(-timewindow:timewindow, AverageTrajectories(1,:),AverageTrajectories(4,:),{'color',cmat/2},1);
        end
        set(gca,'YLim',[0 5]);
        
        % successful trials
        cmat = [0 0 0];
        cmat(z) = 1;
        subplot(3,numel(ZonesToUse),numel(ZonesToUse)+z); hold on;
        HighLim = TargetZones(z,1);
        LowLim = TargetZones(z,2);
        fill([-timewindow -timewindow timewindow timewindow], ...
            [LowLim HighLim HighLim LowLim],cmat/2,'FaceAlpha',0.1,'EdgeColor','none');
        
        for j = 1:3
            cmat = [0 0 0];
            cmat(j) = 1;
            f = find( Trajectories.(['Z',num2str(z)]).ZoneType==j);
            f(find(Trajectories.(['Z',num2str(z)]).Outcome(f,:)~=1),:) = [];
            %f = find( (Trajectories.(['Z',num2str(z)]).ZoneType==j) & (Trajectories.(['Z',num2str(z)]).Outcome==1));
            AverageTrajectories = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).Traces(f,:),1);
            shadedErrorBar(-timewindow:timewindow, AverageTrajectories(1,:),AverageTrajectories(4,:),{'color',cmat/2},1);
        end
        set(gca,'YLim',[0 5]);
        
        % failures
        cmat = [0 0 0];
        cmat(z) = 1;
        subplot(3,numel(ZonesToUse),2*numel(ZonesToUse)+z); hold on;
        HighLim = TargetZones(z,1);
        LowLim = TargetZones(z,2);
        fill([-timewindow -timewindow timewindow timewindow], ...
            [LowLim HighLim HighLim LowLim],cmat/2,'FaceAlpha',0.1,'EdgeColor','none');
        
        for j = 1:3
            cmat = [0 0 0];
            cmat(j) = 1;
            f = find( Trajectories.(['Z',num2str(z)]).ZoneType==j);
            f(find(Trajectories.(['Z',num2str(z)]).Outcome(f,:)~=0),:) = [];
            %f = find((Trajectories.(['Z',num2str(z)]).ZoneType==j) & (Trajectories.(['Z',num2str(z)]).Outcome==0));
            AverageTrajectories = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).Traces(f,:),1);
            shadedErrorBar(-timewindow:timewindow, AverageTrajectories(1,:),AverageTrajectories(4,:),{'color',cmat/2},1);
        end
        set(gca,'YLim',[0 5]);
    end

%     figure('Name',[char(FileNames{i}),'ZoneAlignedSingleTrials']);
%     for z = 1:numel(ZonesToUse)
%             subplot(2,numel(ZonesToUse),z); hold on;
%             plot(-timewindow:timewindow, Trajectories.(['Z',num2str(z)]).TargetZone, 'r');
%             subplot(2,numel(ZonesToUse),z+numel(ZonesToUse)); hold on;
%             plot(-timewindow:timewindow, Trajectories.(['Z',num2str(z)]).NonTarget, 'k');
%     end
end
end