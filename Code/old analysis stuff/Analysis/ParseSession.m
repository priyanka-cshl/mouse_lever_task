function [Output] = ParseSession(MyFileName, ReplotSession, Plotting)

if nargin < 2
    ReplotSession = 0;
    Plotting = 0;
end
    

%% core data extraction (and settings)
    [MyData, MySettings, TargetZones, FakeTargetZones] = ...
        ExtractSessionData(MyFileName);
    
    %% Parse trials
    [Lever, Motor, TrialInfo, TargetZones] = ChunkUpTrials(MyData, TargetZones, FakeTargetZones);
    [Odors, ZonesToUse, LeverTruncated, MotorTruncated] = TruncateTrials(Lever, Motor, TrialInfo, TargetZones);
    
    %% Correct for incorrect Target Zone assignments
    [TrialInfo,MyData] = FixTargetZoneAssignments(MyData,TrialInfo,TargetZones,MySettings);
    if ReplotSession
        RecreateSession(MyData);
    end
    
    %% Get TFs
    [AllTFs] = GetAllTransferFunctions(MySettings, TargetZones(ZonesToUse,:));
    
    %% Trajectory Analysis
%     if i == 1
%         if any(find(~TrialInfo.TransferFunctionLeft))
%             SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1, 1);
%             OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1, 2);
%             [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, 0, 0);
%         else
%             [Trajectories] = SortTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, 1, 1);
%         end
%     else
%         [Trajectories] = OverLayTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones,1);
%     end
    [Trajectories] = PlotTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones, AllTFs, 0, Plotting);
    
    %% Basic session statistics
    [NumTrials] = SessionStats(TrialInfo,Trajectories,ZonesToUse,TargetZones,Plotting);    
    
    %% Histograms
    HistogramOfOccupancy(LeverTruncated, MotorTruncated, TrialInfo, ZonesToUse, TargetZones, AllTFs, Trajectories, Plotting);
    [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, MySettings, Plotting);
    
    Output.TargetZones = TargetZones;
    Output.ZonesToUse = ZonesToUse;
    Output.TrialInfo = TrialInfo;
    Output.Trajectories = Trajectories;
    Output.StayTimes = StayTimes;
    Output.TrialStats = TrialStats;
    
end