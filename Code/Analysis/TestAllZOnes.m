function [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones, DoPlot)
if nargin < 4
    DoPlot = 0;
end

%% initializations
timewindow = 50; % sampling rate of 500 Hz, 50 points = 100ms
for z = 1:numel(ZonesToUse)
    Trajectories.(['Z',num2str(z)]).TargetZone = [];
    Trajectories.(['Z',num2str(z)]).Outcome = [];
    Trajectories.(['Z',num2str(z)]).NonTarget = [];
end

TargetUpLim = TargetZones(ZonesToUse,1);

%% for each trial, analyze trajectory w.r.t. Zone entry for all valid zones
for t = 1:size(LeverTruncated,1) % every trial
    temp = [NaN+ones(1,timewindow), LeverTruncated(t,:), NaN+ones(1,timewindow)];
    for z = 1:numel(ZonesToUse)
        if ~isempty(find(temp==TargetUpLim(z),1))
            timepoint = find(temp==TargetUpLim(z),1);
            if TrialInfo.TargetZoneType(t) == ZonesToUse(z)
                Trajectories.(['Z',num2str(z)]).TargetZone = [Trajectories.(['Z',num2str(z)]).TargetZone; ...
                    temp(timepoint-timewindow:timepoint+timewindow)];
                Trajectories.(['Z',num2str(z)]).Outcome = [Trajectories.(['Z',num2str(z)]).Outcome; TrialInfo.Success(t)];
            else
                Trajectories.(['Z',num2str(z)]).NonTarget = [Trajectories.(['Z',num2str(z)]).NonTarget; ...
                    temp(timepoint-timewindow:timepoint+timewindow)];
            end
        end
    end
end

%% Averages
for z = 1:numel(ZonesToUse)
    AverageTrajectories.(['Z',num2str(z)]).TargetZone = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).TargetZone,1);
    AverageTrajectories.(['Z',num2str(z)]).NonTarget = Mean_NoNaNs(Trajectories.(['Z',num2str(z)]).NonTarget,1);
    if DoPlot
        subplot(1,numel(ZonesToUse),AverageTrajectories.(['Z',num2str(z)]).TargetZone,'r');
        subplot(1,numel(ZonesToUse),AverageTrajectories.(['Z',num2str(z)]).NonTarget,'k');
    end
end

end