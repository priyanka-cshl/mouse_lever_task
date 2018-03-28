function [TrialInfo,MyData] = FixTargetZoneAssignments(MyData,TrialInfo,TargetZones,Params);

% Find trials for which there is no record of successful updates to the Arduino

LeverCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
TZoneCol = find(cellfun(@isempty,regexp(WhatsMyData','InTargetZone'))==0);
if size(MyData,2)>12
    MotorCol = find(cellfun(@isempty,regexp(WhatsMyData','MotorPosition'))==0);
    HomeCol = find(cellfun(@isempty,regexp(WhatsMyData','HomeSensor'))==0);
end

% create a logical vector to get values of perturbed zones
WasPerturbed = cell2mat(cellfun(@(x) max([x; 0]), TrialInfo.FakeZone, 'UniformOutput', false))';
UpdateSuccess = zeros(size(TrialInfo.Timestamps,1),1);
LeverAtHome = zeros(size(TrialInfo.Timestamps,1),1);
Mismatch = zeros(size(TrialInfo.Timestamps,1),1);
SuggestedZone = zeros(size(TrialInfo.Timestamps,1),1);

for t = 1:size(TrialInfo.Timestamps,1)
    if t == 1
        start_idx = 0; 
    else
        start_idx = TrialInfo.Timestamps(t-1,2); % previous trial's off time
    end
    stop_idx = TrialInfo.Timestamps(t,1);
    
    UpdateSuccess(t,1) = any(find((Params(:,1)>=start_idx)&(Params(:,1)<=stop_idx)));
    
    % verify if the motor was off
    start_idx = TrialInfo.TimeIndices(t,1); 
    stop_idx = TrialInfo.TimeIndices(t,2);
    LeverTemp = MyData(start_idx:stop_idx,LeverCol);
    HomeTemp = MyData(start_idx:stop_idx,HomeCol);
    TZoneTemp = MyData(start_idx:stop_idx,TZoneCol);
    MotorTemp = MyData(start_idx:stop_idx,MotorCol);
    
    % A vector to store lever values for assigning target zone in case of
    % mismatch
    LeverVals = [];
    
    % for trials without any perturbation
    if ~WasPerturbed(t)
        if ~isempty( find(TZoneTemp)) % entered TargetZone in this trial
            if numel(intersect(find(HomeTemp),find(TZoneTemp)))>5
                idx = intersect(find(HomeTemp),find(TZoneTemp));
                %LeverAtHome(t,1) = median(LeverTemp(idx));
                LeverVals = LeverTemp(idx);
                MotorLimits(t,:) = [min(MotorTemp(idx)) max(MotorTemp(idx))];
            else
                %LeverAtHome(t,1) = median(LeverTemp(find(TZoneTemp)));
                LeverVals = LeverTemp(find(TZoneTemp));
            end
        else
            LeverVals = NaN;
            % if it didn't enter target zone - then hard to determine what
            % the TF was
        end
    else
        if WasPerturbed(t)>20
            LeverVals = TargetZones(TrialInfo.TargetZoneType(t),2);
        else
            % find the longest stretch when home was on
            HomeOn = find(diff(HomeTemp));
            HomeOff = find(diff(HomeTemp)==-1);
            foo = min(numel(HomeOn),numel(HomeOff));
            HomeStays = [HomeOn(1:foo,1) HomeOff(1:foo,1)];
            HomeStays(:,3) = HomeStays(:,2)-HomeStays(:,1);
            [~,idx] = max(HomeStays(:,3));
            LeverVals = LeverTemp(HomeOn(idx):HomeOff(idx));
            %LeverAtHome(t,1) = median(LeverTemp(HomeOn(idx):HomeOff(idx)));
        end
    end
    LeverAtHome(t,1) = median(LeverVals);
    if (LeverAtHome(t,1)>TargetZones(TrialInfo.TargetZoneType(t),1)) | ...
            (LeverAtHome(t,1)<TargetZones(TrialInfo.TargetZoneType(t),3))
        Mismatch(t,1) = 1;
        ZoneScore = zeros(size(TargetZones,1),1);
        for Z = 1:size(TargetZones,1)
            ZoneScore(Z,1) = numel(find(LeverVals>=TargetZones(Z,3) & LeverVals<=TargetZones(Z,1)));
        end
        [~,SuggestedZone(t,1)] = max(ZoneScore);
        TrialInfo.TargetZoneType(t) = SuggestedZone(t,1);
        MyData(start_idx:stop_idx,2) = TargetZones(SuggestedZone(t,1),1);
        MyData(start_idx:stop_idx,3) = TargetZones(SuggestedZone(t,1),3);
    else
        SuggestedZone(t,1) = NaN;
    end
end
disp(['fixing ',num2str(numel(find(Mismatch))),' targetzone assignments']);
end