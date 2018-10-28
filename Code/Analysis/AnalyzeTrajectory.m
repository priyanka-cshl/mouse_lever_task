function [ThisTrialStats ZoneTimes] = AnalyzeTrajectory(mylevertrace, trialnum, TrialInfo, TargetZones, indicesdeleted)

TrialID = TrialInfo.TrialID(trialnum);
if ~isempty(TrialInfo.StayTimeStart{trialnum})
    [maxstay, stayID]   = max(TrialInfo.StayTime{trialnum});
    entrylatency        = TrialInfo.StayTimeStart{trialnum}(stayID);
    totalstay           = sum(TrialInfo.StayTime{trialnum});
    attempts            = numel(TrialInfo.StayTimeStart{trialnum});
else
    maxstay     = NaN;
    totalstay   = NaN;
    entrylatency= NaN;
    attempts    = 0;
end

if TrialInfo.Success(trialnum)
    rewardlatency = TrialInfo.Reward{trialnum}(1);
else
    rewardlatency = NaN;
end

for i = 1:size(TargetZones,1)
    ZoneTimes(i) = numel(find((mylevertrace<TargetZones(i,1))&(mylevertrace>TargetZones(i,2))));
end

TargetZone = TrialInfo.TargetZoneType(trialnum);
Perturbation = TrialInfo.Perturbation(trialnum,:);
Odor = TrialInfo.Odor(trialnum);

% Perturbation specific analysis
if TrialInfo.Perturbation(trialnum,1)==6
    PerturbationOffsetStart = TrialInfo.FeedbackStart(trialnum) - indicesdeleted;
else
    PerturbationOffsetStart = NaN;
end

ThisTrialStats = [maxstay totalstay entrylatency attempts rewardlatency TargetZone Perturbation PerturbationOffsetStart Odor];
end