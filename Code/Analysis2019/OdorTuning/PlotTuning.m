function [] = PlotTuning(SingleUnits, EphysTuningTrials, MyTuningTrials)
Locations = unique(MyTuningTrials(:,1));
Odors = unique(EphysTuningTrials(:,4));

% delete NaN values
Locations(find(isnan(Locations)),:) = [];

% for i = 1:numel(Locations)
%     Locations(i,2) = numel(find(MyTuningTrials(:,1)==Locations(i)));
% end
% 
% % fill in the NaN values
% [~, x] = min(Locations(:,2));
% MyTuningTrials(1,1) = Locations(x); 

OdorStart = mean(MyTuningTrials(find(MyTuningTrials(:,10)),10)-MyTuningTrials(find(MyTuningTrials(:,10)),5));
OdorOff = OdorStart + mean(MyTuningTrials(find(MyTuningTrials(:,10)),11)-MyTuningTrials(find(MyTuningTrials(:,10)),10));
% Create a matrix of trials
for MyOdor = 1:numel(Odors)
    thisOdor = Odors(MyOdor);
    for MyLocation = 1:numel(Locations(:,1))
        thisLocation = Locations(MyLocation);
        % get all trial IDs that match this location and this odor
        MyTrials = intersect(find(MyTuningTrials(:,1)==thisLocation),find(EphysTuningTrials(:,4)==thisOdor));
        TrialList(MyOdor,MyLocation) = {MyTrials};
        
        % get spike counts for each trial
        for MyUnit = 1:size(SingleUnits,2)
            preodor = []; odor = []; postodor = [];
            for i = 1:numel(MyTrials)
                thisTrialSpikeTimes = SingleUnits(MyUnit).tuningspikes{MyTrials(i)};
                preodor(i) = numel(find(thisTrialSpikeTimes<=OdorStart));
                odor(i) = numel(find(thisTrialSpikeTimes<=OdorOff)) - preodor(i);
                postodor(i) = numel(find(thisTrialSpikeTimes>OdorOff));
            end
%             preodor = [preodor mean(preodor) std(preodor)];
%             odor = [odor mean(odor) std(odor)];
%             postodor = [postodor mean(postodor) std(postodor)];
            SpikeCounts(MyUnit,MyOdor,MyLocation) = {[mean(odor - preodor) std(odor - preodor)/sqrt(i)]};
        end
    end
end

% plot tuning curves
figure;
for MyUnit = 1:size(SingleUnits,2) % for every cell
    TuningCurve = [];
    for MyOdor = 1:numel(Odors)
       for MyLocation = 1:numel(Locations(:,1))
           TuningCurve(MyOdor,MyLocation) = SpikeCounts{MyUnit,MyOdor,MyLocation}(1); 
           TuningSEM(MyOdor,MyLocation) = SpikeCounts{MyUnit,MyOdor,MyLocation}(2);
       end
    end
    if mod(MyUnit,20) 
        subplot(4,5,mod(MyUnit,20));
    else
        subplot(4,5,20);
    end
    plot(Locations,TuningCurve(1,:),'k');
    hold on
    plot(Locations,TuningCurve(2,:),'color',Plot_Colors('r'));
    plot(Locations,TuningCurve(3,:),'color',Plot_Colors('o'));
    plot(Locations,TuningCurve(4,:),'color',Plot_Colors('t'));
    title(['Unit# ',num2str(MyUnit)]);

    if mod(MyUnit,20) == 0
        figure;
    end
end

end