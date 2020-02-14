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
        
        [sniff_stamps] = GetRespirationTimeStamps(Sniffs, 0.1);
        
%         [pks,dep,pid,did] = peakdet(Sniffs-median(Sniffs), 0.05);
        
        rid = sniff_stamps(:,3);
        
        if numel(find(rid>start_idx))>=4 & numel(find(rid<start_idx))>=2
            count = count + 1;
            % find the first valley before trial start
%             [idx] = find(rid<=start_idx,1,'last');
            [~,idx] = min(abs(rid-start_idx));
%             
            if rid(idx)<start_idx
%                 disp(2);
            else
                disp(2);
            end
            
            amp(count,1) = min(Lever(rid(idx):rid(idx+1)));
            amp(count,2) = TrialInfo.TargetZoneType(mytrial);
            phase(count,1) = 2*pi*(start_idx - rid(idx))/(rid(idx+1) - rid(idx));
            latency(count,1) = 2*(start_idx - rid(idx)); % in ms
            %keyboard
        end
        
    end
    
end

figure;
subplot(1,3,1);

for i = 1:12; errorbar(i,mean(amp(find(amp(:,2)==i),1)),std(amp(find(amp(:,2)==i),1))/sqrt(numel(amp(find(amp(:,2)==i))))); hold on; end
for i = 1:12; plot(i,mean(amp(find(amp(:,2)==i),1)),'ok'); end

subplot(1,3,2);
phase(phase<0) = NaN;
polarhistogram(phase,18);

subplot(1,3,3);
latency(latency<0) = NaN;
histogram(latency,10);


