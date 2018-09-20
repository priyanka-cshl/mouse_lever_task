function [AllTraces] = PlotOpenLoopPID(DataIn)

    mycolors = brewermap(200,'*Blues');
    set(groot,'defaultAxesColorOrder',mycolors);
    
% sort by different odors
for myodor = 1:numel(DataIn.Odors)
    alltrials = find(DataIn.TrialInfo.Odor==DataIn.Odors(myodor));
    alllocations = unique(DataIn.TrialInfo.TargetZoneType(alltrials,:));
    for mylocation = 1:numel(alllocations)
        % sub-sort by different locations
        mytrials = find((DataIn.TrialInfo.Odor==DataIn.Odors(myodor)) & ...
            (DataIn.TrialInfo.TargetZoneType==alllocations(mylocation)));
        mytraces = zeros(numel(mytrials),size(DataIn.PID,2));
        for i = 1:numel(mytrials)
            whichtrial = mytrials(i);
            odorstart = DataIn.TrialInfo.StayTimeStart{whichtrial};
            % for each trace, subtract pre-odor baseline
            mytraces(i,:) = DataIn.PID(whichtrial,:) - mean(DataIn.PID(whichtrial,1:odorstart));
        end
        AllTraces.(['Odor',num2str(DataIn.Odors(myodor))]).(['Location',num2str(alllocations(mylocation))]) = mytraces;
    end
    %subplot(1,4,myodor); plot((1:size(mytraces,2))/2, mytraces'); set(gca,'YLim',[-0.5 2],'XLim',[0 1500]);
end
end