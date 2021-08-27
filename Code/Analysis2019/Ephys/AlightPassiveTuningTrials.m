function [EphysTuningTrials] = AlightPassiveTuningTrials(TuningTrials, TTLs, SkipTrials)

if (size(TTLs.Trial,1) - SkipTrials) >= size(TuningTrials,1)
    EphysTuningTrials = TTLs.Trial(SkipTrials+1:end,:);
    EphysTuningTrials(:,8) = (SkipTrials+1):size(TTLs.Trial,1);
    
    % delete any values with trial duration < avg. tuning trial duration
    foo = find(EphysTuningTrials(:,3)<floor(min(TuningTrials(:,7))));
    EphysTuningTrials(foo,:) = [];
    
    % Assign odor identities
    for i = 1:size(EphysTuningTrials,1)
        tstart = EphysTuningTrials(i,1);
        tstop = EphysTuningTrials(i,2);
        O1 = intersect(find(TTLs.Odor1(:,1)>tstart),find(TTLs.Odor1(:,1)<tstop));
        O2 = intersect(find(TTLs.Odor2(:,1)>tstart),find(TTLs.Odor2(:,1)<tstop));
        O3 = intersect(find(TTLs.Odor3(:,1)>tstart),find(TTLs.Odor3(:,1)<tstop));
        if ~isempty(O1)
            EphysTuningTrials(i,4) = 2;
            EphysTuningTrials(i,5:7) = TTLs.Odor1(O1,:);
        elseif ~isempty(O2)
            EphysTuningTrials(i,4) = 3;
            EphysTuningTrials(i,5:7) = TTLs.Odor2(O2,:);
        elseif ~isempty(O3)
            EphysTuningTrials(i,4) = 4;
            EphysTuningTrials(i,5:7) = TTLs.Odor3(O3,:);
        else
            EphysTuningTrials(i,4) = 1;
        end
    end
    
    % Align the ephys and behavior trial lists
    idx = strfind(EphysTuningTrials(:,4)',TuningTrials(2:end,2)');
    EphysTuningTrials(1:idx-2,:) = [];
    EphysTuningTrials(size(TuningTrials,1)+1:end,:) = [];
    
    if ~any(EphysTuningTrials(2:end,4)-TuningTrials(2:end,2))
        display('odor sequences match');
    else
        display('odor sequences do not match');
        keyboard;
    end
else
    EphysTuningTrials = [];
end
