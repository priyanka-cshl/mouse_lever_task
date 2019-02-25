% sniff and movement analysis
count = 0;
clear amp
for mytrial = 1:numel(TrialInfo.TrialID) % every trial
    
    if TrialInfo.Valid(mytrial)>=0
        
        
        % relevant traces
        Lever = cell2mat(Traces.Lever(mytrial)); % in samples @500 Hz
        Sniffs = cell2mat(Traces.Sniffs(mytrial)); % in samples @500 Hz
        
        % relevant time points
        start_idx = TrialInfo.TimeIndices(mytrial,1);
        stop_idx = TrialInfo.TimeIndices(mytrial,2);
        
        [pks,dep,pid,did] = peakdet(Sniffs-median(Sniffs), 0.05);
        
        if numel(find(pid>start_idx))>=4 & numel(find(pid<start_idx))>=2
            count = count + 1;
            % find the first valley before trial start
            [~,idx] = min(abs(pid-start_idx));
            amp(count,1) = min(Lever(pid(idx):pid(idx+1)));
            amp(count,2) = TrialInfo.TargetZoneType(mytrial);
            %keyboard
        end
        
    end
    
end