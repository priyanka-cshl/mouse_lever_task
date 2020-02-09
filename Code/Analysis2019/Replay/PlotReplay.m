function [] = PlotReplay(Traces, TrialInfo, Replay, SingleUnits)

figure;

for MyUnit = 1:size(SingleUnits,2) % for every cell
    subplot(6,4,MyUnit);
    
    MySpikeTimes = [];
    
    % first collate spikes for the original close loop stretch of replayed trials 
    MyTrials = Replay.CloseLoopTrialIDs{1};
    offset = 0; 
    for i = 1:numel(MyTrials)
        thisTrialSpikeTimes = SingleUnits(MyUnit).spikes{MyTrials(i)};
        MySpikeTimes = [MySpikeTimes; ...
            thisTrialSpikeTimes + offset];
        offset = offset + TrialInfo.TraceDuration(MyTrials(i));
    end
    
    plot(MySpikeTimes,1,'.k');
    hold on
    
    % plot the replay spike times
    MyTrials = Replay.ReplayTrialIDs{1}(:,1);
    MyScaling = Replay.ReplayTrialIDs{1}(:,2);
    for i = 1:numel(MyTrials)
        thisTrialSpikeTimes = SingleUnits(MyUnit).spikes{MyTrials(i)};
        % adjust temporal stretches
        thisTrialSpikeTimes = thisTrialSpikeTimes*MyScaling(i); 
        plot(thisTrialSpikeTimes,1+i,'.r');
    end
    
end

end