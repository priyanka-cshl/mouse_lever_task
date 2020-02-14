% sniff and movement analysis
count = 0;
clear amp;
clear phase;
for mytrial = 1:numel(TrialInfo.TrialID) % every trial
    
    if TrialInfo.Valid(mytrial)>=0

        % relevant traces
        Lever = cell2mat(Traces.Lever(mytrial)); % in samples @500 Hz
        Sniffs = cell2mat(Traces.Sniffs(mytrial)); % in samples @500 Hz
        
        % relevant time points
        start_idx = TrialInfo.TimeIndices(mytrial,1);
        stop_idx = TrialInfo.TimeIndices(mytrial,2);
        odor_start = round(TrialInfo.OdorStart(mytrial,2)*500);
        
        [sniff_stamps] = GetRespirationTimeStamps(-Sniffs, 0.2);
        
        if ~isempty(sniff_stamps) & ...
                numel(find(sniff_stamps(:,3)>start_idx))>=4 ...
                & numel(find(sniff_stamps(:,3)<start_idx))>=2
            
            count = count + 1;
            
            % find the inhalation start before movt. start
            %[~,idx] = min(abs(sniff_stamps(:,3)-start_idx));
            idx = find(sniff_stamps(:,3)<start_idx,1,'last');
%             if sniff_stamps(idx,2)<start_idx
%                 cyclestart = sniff_stamps(idx,2);
%                 cyclestop = sniff_stamps(idx+1,2);
%             else
%                 cyclestart = sniff_stamps(idx-1,2);
%                 cyclestop = sniff_stamps(idx,2);
%             end
            cyclestart = sniff_stamps(idx,3);
            cyclestop = sniff_stamps(idx+1,3);
            cycletime = cyclestop - cyclestart;
            exh_start = find(sniff_stamps(:,2)>cyclestart,1,'first');
            exh_start = sniff_stamps(exh_start,2);
            inh_start = find(sniff_stamps(:,1)<cyclestart,1,'last');
            inh_start = sniff_stamps(inh_start,1);
            movt_start = start_idx;
            phase(count,1) = 2*pi*(exh_start - cyclestart)/cycletime;
            phase(count,2) = 2*pi*(movt_start - cyclestart)/cycletime;
            phase(count,3) = 2*pi + 2*pi*(inh_start - cyclestart)/cycletime;
            
            amp(count,1) = min(Lever(cyclestart:cyclestop));
            amp(count,2) = TrialInfo.TargetZoneType(mytrial,1);
            amp(count,3) = min(Lever(cyclestop:sniff_stamps(idx+2,3)));
            
%             if movt_start<=inh_end
%                 phase(count) = pi*(movt_start - inh_start)/(inh_end - inh_start);
%             else
%                 phase(count) = pi + pi*(movt_start - inh_end)/(next_inh - inh_end);
%             end
            
        end
        
    end
    
end

figure;
subplot(1,3,1);
whichcol = 1;
for i = 1:12; errorbar(i,mean(amp(find(amp(:,2)==i),whichcol)),std(amp(find(amp(:,2)==i),whichcol))/sqrt(numel(amp(find(amp(:,2)==i))))); hold on; end
for i = 1:12; plot(i,mean(amp(find(amp(:,2)==i),whichcol)),'ok'); end

subplot(1,3,2);
whichcol = 3;
for i = 1:12; errorbar(i,mean(amp(find(amp(:,2)==i),whichcol)),std(amp(find(amp(:,2)==i),whichcol))/sqrt(numel(amp(find(amp(:,2)==i))))); hold on; end
for i = 1:12; plot(i,mean(amp(find(amp(:,2)==i),whichcol)),'ok'); end

subplot(1,3,3);
phase(phase<0) = NaN;
polarhistogram(phase(:,2),18);
hold on
polarhistogram(phase(:,1),18,'DisplayStyle','stairs','Linewidth',2);
polarhistogram(phase(:,3),18,'DisplayStyle','stairs','Linewidth',2);

% 
% subplot(1,3,3);
% latency(latency<0) = NaN;
% histogram(latency,10);


