% plot PSTH using cellbase predefined epochs and events
function plotPSTHforPG(cellid, eventid) 
    figure
    subplot(2,1,1);
    pos1 = [0.12 0.55 0.8 0.4];
    subplot('Position',pos1)
    hold on
    ylabel('trial number', 'FontName', 'Avenir', 'FontSize', 18);
    yind = 1;
    bins = -3000:1:3000; %depends on time range of pre-aligned spike times
    psth = zeros(length(bins),1);

    %here I load event times and spike times, pre-aligned on same clock
    TE = loadcb(cellid, 'TrialEvents');
    SP = loadcb(cellid, 'EventSpikes');
    
    if strcmp(eventid,'ScreenOn')
        %these are spike times pre-aligned to TTL of interest
        spikes = SP.event_stimes{1,1};

        %selecting only valid trials
        fullstimulusidx = find(~isnan(TE.ScreenOnAbsSync));
        %calculating movement and reward times relative to TTL of interest
        movementtimes = TE.CenterOut - TE.ScreenOnRelSync;
        rewardtimes = TE.RewardOnset - TE.ScreenOnRelSync;
        for idx = fullstimulusidx %iterate through valid trials
            t = spikes{1,idx}.*1000; %scaling to change spike times in s to ms
            if ~isempty(t)
                for ii = 1:length(t) %plot raster line
                    line([t(ii) t(ii)],[yind-1 yind],'Color','k');
                    hold on
                end
                if ~isnan(movementtimes(idx)) %plot movement time, if exist
                plot(movementtimes(idx)*1000, yind-1, 'gs', 'MarkerSize', 3, 'LineWidth', 1);
                hold on
                end 
                if ~isnan(rewardtimes(idx)) %plot reward time, if exist
                plot(rewardtimes(idx)*1000, yind-1, 'cs', 'MarkerSize', 3, 'LineWidth', 1);
                hold on
                end 
                for inx= 1:length(bins)-1 %calculate # spikes in ms bins
                    comp1 = t > bins(inx);
                    comp2 = t < bins(inx + 1);
                    psth(inx) = psth(inx) + sum((comp1+comp2) == 2);
                end
            end
            hold on
            yind = yind+1;
        end
        hold on
        psth = psth.*1000./length(fullstimulusidx); %scaling to adjust units to Hz
        %raster plotting conventions,axes 
        line([0,0],[0,length(fullstimulusidx)],'Color','r', 'LineWidth',3); 
        axis([-3000,3000, 0, length(fullstimulusidx)]);
    elseif strcmp(eventid,'MovementOn')
        spikes = SP.event_stimes{3,1};
        movementidx = find(~isnan(TE.CenterOut));
        rewardtimes = TE.RewardOnset - TE.CenterOut;
        for idx = movementidx
            t = spikes{1,idx}.*1000;
            if ~isempty(t)
                for ii = 1:length(t)
                    line([t(ii) t(ii)],[yind-1 yind],'Color','k');
                    hold on
                end
                if ~isnan(rewardtimes(idx))
                plot(rewardtimes(idx)*1000, yind-1, 'cs', 'MarkerSize', 3, 'LineWidth', 1);
                hold on
                end 
                for inx= 1:length(bins)-1
                    comp1 = t > bins(inx);
                    comp2 = t < bins(inx + 1);
                    psth(inx) = psth(inx) + sum((comp1+comp2) == 2);
                end
            end
            hold on
            yind = yind+1;
        end
        hold on
        psth = psth.*1000./length(movementidx); %multiplicative factor to adjust units to Hz
        line([0,0],[0,length(movementidx)],'Color','g', 'LineWidth',3);
        axis([-3000,3000, 0, length(movementidx)]);
    elseif strcmp(eventid,'RewardOn')
        spikes = SP.event_stimes{2,1};
        rewardidx = find(~isnan(TE.RewardOnset));
        for idx = rewardidx
            t = spikes{1,idx}.*1000;
            if ~isempty(t)
                for ii = 1:length(t)
                    line([t(ii) t(ii)],[yind-1 yind],'Color','k');
                    hold on
                end
                for inx= 1:length(bins)-1
                    comp1 = t > bins(inx);
                    comp2 = t < bins(inx + 1);
                    psth(inx) = psth(inx) + sum((comp1+comp2) == 2);
                end
            end
            hold on
            yind = yind+1;
        end
        hold on
        psth = psth.*1000./length(rewardidx); %multiplicative factor to adjust units to Hz
        line([0,0],[0,length(rewardidx)],'Color','b', 'LineWidth',3);
        axis([-3000,3000, 0, length(rewardidx)]);
    end
    
    %plotting psth below raster
    subplot(2,1,2); 
    pos2 = [0.12 0.1 0.8 0.4];
    subplot('Position',pos2)
    hold on
    %define kernel sigma for convolution/smoothing PSTH
    sigma = 20;
    conv_psth = convPSTH(psth, sigma);

    plot(bins/1000, conv_psth, 'k', 'LineWidth', 3);

    %plotting conventions, axis labels, etc.
    line([0,0],[0,max(conv_psth)],'Color','r', 'LineWidth',3);
    ylim=[0,max(conv_psth)];
    
    xlabel('time (ms)', 'FontName', 'Avenir', 'FontSize', 18);
    ylabel('firing rate (Hz)', 'FontName', 'Avenir', 'FontSize', 18);
    box off
    
    