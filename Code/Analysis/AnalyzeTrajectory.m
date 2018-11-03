function [ThisTrialStats ZoneTimes Exhalation Inhalation] = AnalyzeTrajectory(mylevertrace, trialnum, TrialInfo, TargetZones, indicesdeleted)

TrialID = TrialInfo.TrialID(trialnum);
if ~isempty(TrialInfo.StayTimeStart{trialnum})
    [maxstay, stayID]   = max(TrialInfo.StayTime{trialnum});
    entrylatency        = TrialInfo.StayTimeStart{trialnum}(stayID);
    totalstay           = sum(TrialInfo.StayTime{trialnum})/TrialInfo.Duration(trialnum);
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

if ~isempty(TrialInfo.Inhalation)
    Inhalation = {cell2mat(TrialInfo.Inhalation(trialnum)) - TrialInfo.TimeIndices(trialnum,1)};
    Exhalation = {cell2mat(TrialInfo.Exhalation(trialnum)) - TrialInfo.TimeIndices(trialnum,1)};
else
    Inhalation = {[]};
    Exhalation = {[]};
end

% Perturbation specific analysis
switch TrialInfo.Perturbation(trialnum,1)
    case {6,7,9}
        if isfield(TrialInfo,'PerturbationStart')
            PerturbationStart = TrialInfo.PerturbationStart(trialnum) - indicesdeleted;
        else
            PerturbationStart = NaN;
        end
        if isfield(TrialInfo,'FeedbackStart')
            PerturbationOffsetStart = TrialInfo.FeedbackStart(trialnum) - indicesdeleted;
        else
            PerturbationOffsetStart = NaN;
        end
    case 10
        PerturbationStart = TrialInfo.PerturbationStart(trialnum) - indicesdeleted;
        PerturbationOffsetStart = TrialInfo.FeedbackStart(trialnum) - indicesdeleted;
    otherwise
        PerturbationOffsetStart = NaN;
        PerturbationStart = NaN;
end

ThisTrialStats = [maxstay totalstay entrylatency attempts rewardlatency TargetZone Perturbation PerturbationOffsetStart Odor PerturbationStart];
end