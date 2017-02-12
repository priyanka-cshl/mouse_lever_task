function [Trajectories] = TestAllZOnes(LeverTruncated, TrialInfo, ZonesToUse, TargetZones)

%% initializations
global timewindow;

for z = 1:numel(ZonesToUse)
    Trajectories.(['Z',num2str(z)]).TargetZone = [];
    Trajectories.(['Z',num2str(z)]).Outcome = [];
    Trajectories.(['Z',num2str(z)]).NonTarget = [];
end

TargetUpLim = mean(TargetZones(ZonesToUse,1:2),2);

%% for each trial, analyze trajectory w.r.t. Zone entry for all valid zones
for t = 1:size(LeverTruncated,1) % every trial
    temp = [NaN+ones(1,timewindow), LeverTruncated(t,:), NaN+ones(1,timewindow)];
    for z = 1:numel(ZonesToUse)
        [MyTraces] = DetectTargetZoneCross(temp,TargetUpLim(z));
        if ~isempty(MyTraces)
            if TrialInfo.TargetZoneType(t) == ZonesToUse(z)
                Trajectories.(['Z',num2str(z)]).TargetZone = [Trajectories.(['Z',num2str(z)]).TargetZone; MyTraces];
                Trajectories.(['Z',num2str(z)]).Outcome = [Trajectories.(['Z',num2str(z)]).Outcome; zeros(size(MyTraces,1),1) + TrialInfo.Success(t)];
            else
                Trajectories.(['Z',num2str(z)]).NonTarget = [Trajectories.(['Z',num2str(z)]).NonTarget; ; MyTraces];
            end
        end
    end
end

end