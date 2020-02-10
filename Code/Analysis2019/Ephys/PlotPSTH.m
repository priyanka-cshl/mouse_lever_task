% function to plot spikes aligned by trial types
function [] = PlotPSTH(whichcluster,TrialInfo,spiketimes)

% [Traces, TrialInfo, TargetZones] = ParseTrials(MyData, MySettings, TargetZones, sessionstart, sessionstop);
% [spiketimes] = Spikes2Trials(myephysdir);

% eg. plot spikes of cluster 1 for all trials of odor 1
% whichcluster = 1;
% whichodor = 1;
perturbation = 0;

for whichodor = 1:3
    whichtrials = find(TrialInfo.Odor==whichodor & TrialInfo.Perturbation(:,1)==perturbation);
    counts(1:12) = 0;
    
    for i = 2:numel(whichtrials)-1
        trial_idx = whichtrials(i);
        
        % sort by targetzone type
        whichzone = TrialInfo.TargetZoneType(trial_idx);
        counts(whichzone) = counts(whichzone) + 1;
        myspikes = cell2mat(spiketimes(whichcluster).spikes(TrialInfo.TrialID(trial_idx)));
        whichplot = 3*whichzone - (3-whichodor);
        
        if ~isempty(myspikes)
            time2align = TrialInfo.Timestamps(trial_idx,1);
            myspikes = round((myspikes - time2align)*1000); % in ms
            subplot(12,3,whichplot);
            hold on
            for eachspike = 1:numel(myspikes) % plot raster line
                line([myspikes(eachspike) myspikes(eachspike)],...
                    [counts(whichzone)-1 counts(whichzone)],'Color','k');
                hold on
            end
            
            % plot trace start
            tracestart = round((-time2align)*1000);
            line([tracestart tracestart],...
                    [counts(whichzone)-1 counts(whichzone)],'Color','c', 'LineWidth', 1);
            
            % plot odor start time
            odorstart = round((TrialInfo.OdorStart(trial_idx,1)-time2align)*1000);
            line([odorstart odorstart],...
                    [counts(whichzone)-1 counts(whichzone)],'Color','r', 'LineWidth', 1);
            %plot(odorstart, counts(whichzone)-1, 'rs', 'MarkerSize', 3, 'LineWidth', 1);
            
            % plot of target zone entry for longest stay
            targetstays = cell2mat(TrialInfo.InZone(trial_idx));
            if ~isempty(targetstays)
                [~,targetentry] = max(targetstays(:,2) - targetstays(:,1));
                targetentry = round((targetstays(targetentry,1) - time2align)*1000);
                line([targetentry targetentry],...
                    [counts(whichzone)-1 counts(whichzone)],'Color','b', 'LineWidth', 1);
                %plot(targetentry, counts(whichzone)-1, 'bs', 'MarkerSize', 3, 'LineWidth', 1);
            end
        end

    end
    
    for myplot = 1:12
            whichplot = 3*myplot - (3-whichodor);
            subplot(12,3,whichplot);
            set(gca,'XLim',[-5000 5000],'YLim',[-1 max(counts)+1]);
            if myplot < 12
                set(gca,'YTick',[],'XTick',[]);
            else
                set(gca,'YTick',[],'XTick',[-5000 0 5000]);
            end
    end
    
    
end

