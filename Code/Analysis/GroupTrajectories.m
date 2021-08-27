function [Aligned, TrajectoryStats, ZoneTimes, Exhalation, Inhalation] = GroupTrajectories(Traces, TrialInfo, TargetZones, Params)

%% Align all trajectories to the time-point when they start moving the lever
% ie. lever voltage goes below thershold for Trigger ON = ~4.8V
TraceTypes = fieldnames(Traces);
idx = []; % initialize with no valid trial indices
trialcounts = 0;
for i = 1:size(Traces.Lever,1) % all trials
    % align to trial start
    % find the time-point at which the lever dropped below 4.75 V
    t = find(Traces.Lever(i,:) < 5, 1);
    if ~isempty(t) % valid trial
        idx = [idx; i];
        trialcounts = trialcounts + 1;
        for j = 1:size(TraceTypes,1)
            if j == 1
                mylevertrace = Traces.([char(TraceTypes(j))])(i,t:end);
            end
            Aligned.([char(TraceTypes(j))])(trialcounts,:) = [Traces.([char(TraceTypes(j))])(i,t:end) NaN*ones(1,t-1)];
        end
        
        % do some trajectory analysis?
        [TrajectoryStats(trialcounts,:), ZoneTimes(trialcounts,:) Exhalation(trialcounts,:) Inhalation(trialcounts,:)] = ...
            AnalyzeTrajectory(mylevertrace, i, TrialInfo, TargetZones, t);
    end
end
end
