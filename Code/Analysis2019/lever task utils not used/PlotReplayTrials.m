
function [] = PlotReplayTrials(Replay, TrialInfo, TargetZones, SingleUnits, TTLs, whichUnits)
global SampleRate;
global MyFileName;
global whichreplay;
global savereplayfigs;

%% Behavior
trials_per_replay = size(Replay.ReplayTrialIDs{whichreplay},1);

% initialize figure
H1 = figure;
H2 = figure;

%% Prep Traces
% data (specific to close loop)
timestamps = (1:size(Replay.CloseLoopTraces{whichreplay},1))'/SampleRate;
Lever   = Replay.CloseLoopTraces{whichreplay}(:,2);
Motor   = Replay.CloseLoopTraces{whichreplay}(:,3);
Sniffs  = Replay.CloseLoopTraces{whichreplay}(:,5);
Licks   = Replay.CloseLoopTraces{whichreplay}(:,6);
Rewards = Replay.CloseLoopTraces{whichreplay}(:,8);

% data (common to both)
Trial   = Replay.CloseLoopTraces{whichreplay}(:,7);
TZ_Up   = Replay.CloseLoopTraces{whichreplay}(:,9);
TZ_Low  = Replay.CloseLoopTraces{whichreplay}(:,9);
% change TZ vector to TZ_lims
MyZones = flipud(unique(TZ_Up));
for i = 1:numel(MyZones)
    whichzone = MyZones(i);
    TZ_Up(TZ_Up==whichzone) = TargetZones(find(TargetZones(:,2)==whichzone),1);
    TZ_Low(TZ_Low==whichzone) = TargetZones(find(TargetZones(:,2)==whichzone),3);
end
TZ = [TZ_Low TZ_Up];
MotorTZ = 0*TZ;
MotorTZ(:,1) = -8+MotorTZ(:,1);
MotorTZ(:,2) = 8+MotorTZ(:,2);

figure(H1);
subplot(trials_per_replay+1,1,1);
PlotBehavior(timestamps,Lever,Sniffs,Licks,Rewards,Trial,TZ,[]);
set(gca,'YLim',[-0.4 8],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);

figure(H2);
subplot(trials_per_replay+1,1,1);
PlotBehavior(timestamps,(Motor+100)/40,[],[],[],Trial,(MotorTZ+100)/40,[]);
set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);

for i = 1:trials_per_replay
    % data (specific to open loop)
    %     xaxis = Replay.ReplayTrialIDs{whichreplay}(i,2)*(1:length(Replay.ReplayTraces{whichreplay,i}(:,3)));
    %     timestamps2 = xaxis'/SampleRate;
    timestamps2 = (1:size(Replay.ReplayTraces{whichreplay,i},1))'/SampleRate;
    Lever   = Replay.ReplayTraces{whichreplay,i}(:,2);
    Motor   = Replay.ReplayTraces{whichreplay,i}(:,3);
    Sniffs  = Replay.ReplayTraces{whichreplay,i}(:,5);
    Licks   = Replay.ReplayTraces{whichreplay,i}(:,6);
    Rewards = Replay.ReplayTraces{whichreplay,i}(:,8);
    
    figure(H1);
    subplot(trials_per_replay+1,1,i+1);
    PlotBehavior(timestamps,Lever,Sniffs,Licks,Rewards,Trial,TZ,timestamps2);
    set(gca,'YLim',[-0.4 8],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
    
    figure(H2);
    subplot(trials_per_replay+1,1,i+1);
    PlotBehavior(timestamps,(Motor+100)/40,[],[],[],Trial,(MotorTZ+100)/40,timestamps2);
    set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
end

if savereplayfigs
    figure(H1);
    saveas(gcf,[MyFileName,'_ReplayBehavior.fig']);
    close(gcf);
    
    figure(H2);
    saveas(gcf,[MyFileName,'_ReplayMotor.fig']);
    close(gcf);
end

%% Ephys
if nargin>3 && ~isempty(SingleUnits)
    if nargin<6
        whichUnits = 1:size(SingleUnits,2);
    end
    
    units_per_fig = 5;
    figure;
    
    for i = 1:numel(whichUnits) % for every cell
        MyUnit = whichUnits(i);
        
        if mod(MyUnit,units_per_fig)
            subplot(units_per_fig,1,mod(MyUnit,units_per_fig));
        else
            subplot(units_per_fig,1,units_per_fig);
        end
        
        % plot the trial structure
        PlotBehavior(timestamps,[],[],[],[],Trial,[],[]);
        set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
        
        % Get Spikes
        allspikes = SingleUnits(MyUnit).trialalignedspikes;
        MySpikeTimes = [];
        
        % first collate spikes for the original close loop stretch of replayed trials
        MyTrials = Replay.CloseLoopTrialIDs{whichreplay};
        offset = 0;        
        for thisTrial = 1:numel(MyTrials)
            thisTrialSpikeTimes = allspikes(SingleUnits(MyUnit).trialtags == MyTrials(thisTrial));
            MySpikeTimes = [MySpikeTimes; thisTrialSpikeTimes + offset];
            offset = offset + TrialInfo.TraceDuration(MyTrials(thisTrial));
        end
        
        row_idx = 1;
        for eachspike = 1:numel(MySpikeTimes) % plot raster line
            line([MySpikeTimes(eachspike) MySpikeTimes(eachspike)],...
                [row_idx-1 row_idx],'Color','k');
            hold on
        end
        %     plot(MySpikeTimes,1,'.k');
        %     hold on
        
        % plot the replay spike times
        MyTrials = Replay.ReplayTrialIDs{whichreplay}(:,1);
        for thisTrial = 1:numel(MyTrials)
            OriginalSpikeTimes = allspikes(SingleUnits(MyUnit).trialtags == MyTrials(thisTrial));
            % these spike times are w.r.t. Trial start + start offset
            thisTrialSpikeTimes = NaN*OriginalSpikeTimes;
            thisTrialSpikeTags = NaN*OriginalSpikeTimes;
            
            % split this stretch into trials within the long replay trial
            for subtrial = 1:size(TTLs.Replay{whichreplay,thisTrial},1)
                tstart = TTLs.Replay{whichreplay,thisTrial}(subtrial,1) - TTLs.Replay{whichreplay,thisTrial}(1,1);
                tstop  = TTLs.Replay{whichreplay,thisTrial}(subtrial,2) - TTLs.Replay{whichreplay,thisTrial}(1,1);
                thisTrialSpikeTimes(find(OriginalSpikeTimes>=tstart & OriginalSpikeTimes<tstop)) = ...
                    OriginalSpikeTimes(find(OriginalSpikeTimes>=tstart & OriginalSpikeTimes<tstop)) ...
                    - tstop + Replay.ReplayChunks{whichreplay,thisTrial}(subtrial);
                thisTrialSpikeTags(find(OriginalSpikeTimes>=tstart & OriginalSpikeTimes<tstop)) = subtrial;
            end
            
            % adjust temporal stretches
            %thisTrialSpikeTimes = thisTrialSpikeTimes*MyScaling(thisTrial);
            row_idx = thisTrial+1;
            for eachspike = 1:numel(thisTrialSpikeTimes) % plot raster line
                line([thisTrialSpikeTimes(eachspike) thisTrialSpikeTimes(eachspike)],...
                    [row_idx-1 row_idx],'Color',Plot_Colors('r'));
                hold on
            end
            %plot(thisTrialSpikeTimes,1+i,'.r');
        end
        title(['Unit# ',num2str(MyUnit)]);
        
        if mod(MyUnit,units_per_fig) == 0
            if savereplayfigs
                saveas(gcf,[MyFileName,'_MyUnits_',num2str(MyUnit/units_per_fig),'.fig']);
                close(gcf);
            end
            figure;
        end
    end
    
    saveas(gcf,[MyFileName,'_MyUnits_',num2str(MyUnit/units_per_fig),'.fig']);
    close(gcf);
    
end

end