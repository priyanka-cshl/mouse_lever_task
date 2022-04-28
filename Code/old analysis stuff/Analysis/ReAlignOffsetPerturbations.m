
function [TrajectoriesOut, TrajectoriesIn] = ReAlignOffsetPerturbations(TrajectoriesIn,HoldTimes,Offsets,ZoneLimits)

% Zone LImits
HighLim = ZoneLimits(1);
LowLim = ZoneLimits(3);

for i = 1:size(TrajectoriesIn,1)
    temp = TrajectoriesIn(i,:);
    offset = Offsets(i);
    holdtime = HoldTimes(i);
    
    % threshold any points outside target zone limits
    temp(temp>=HighLim) = HighLim;
    temp(temp<=LowLim) = LowLim;
    tempdiff = diff(temp);
    tempdiff(tempdiff~=0)=1;
    
    % find points of target zone entry and exit
    f = find(diff(tempdiff)~=0)';
    if size(f,1)>1
        if mod(length(f),2)
            f(end+1,:) = find(~isnan(temp),1,'last');
        end
        crosses = [f(1:2:end) f(2:2:end)];
        crosses(:,3) = crosses(:,2) - crosses(:,1);
    else
        crosses = [];
    end

    if ~isempty(crosses)
        f = find(crosses(:,3)>=ceil(holdtime/4),1,'first');
        % /4 bcz, perturbation is triggered at half the reward hold time +
        % sampling rate = 0.5Khz
    else
        f = [];
    end
    
    if ~isempty(f)
        perturbationstart_idx = crosses(f,1) + ceil(holdtime/4);
        if perturbationstart_idx < 500
            nans_to_pad = 500 - perturbationstart_idx;
            TrajectoriesOut(i,:) = [NaN*(ones(1,nans_to_pad)) TrajectoriesIn(i,:) NaN*(ones(1,perturbationstart_idx))];
        else
            points_to_remove = perturbationstart_idx - 500;
            TrajectoriesOut(i,:) = [TrajectoriesIn(i,:) NaN*(ones(1,500))];
        end
    else
        TrajectoriesOut(i,:) = NaN*[TrajectoriesIn(i,:) NaN*(ones(1,500))];
        TrajectoriesIn(i,:) = NaN*TrajectoriesIn(i,:);
    end
    
end
 
end

            