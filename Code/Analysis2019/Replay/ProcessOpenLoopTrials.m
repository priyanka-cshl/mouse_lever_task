
function [Physiology] = ProcessOpenLoopTrials(Replay, TrialInfo, SingleUnits, TTLs, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('whichreplays', [], @(x) isnumeric(x));
params.addParameter('plotfigures', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('savefigures', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('whichunits', [], @(x) isnumeric(x));

% extract values from the inputParser
params.parse(varargin{:});
allreplays = params.Results.whichreplays;
plotreplayfigs = params.Results.plotfigures;
savereplayfigs = params.Results.savefigures;
whichUnits = params.Results.whichunits;

global SampleRate;
global MyFileName;
global TargetZones;

if isempty(allreplays)
    allreplays = 1:numel(Replay.TemplateTraces.TrialIDs);
end

if ~isempty(SingleUnits) && isempty(whichUnits)
    whichUnits = 1:size(SingleUnits,2);
end

for x = 1:numel(allreplays) % for every unique replay stretch
    whichreplay = allreplays(x);
    
    %% 1. Behavior
    
    % get trace length from the replay traces
    tracelength = size(Replay.ReplayTraces.Lever{whichreplay},1);
    
    TraceNames = {'Lever' 'Motor' 'Sniffs' 'Licks' 'Rewards'}; 
    for i = 1:numel(TraceNames)
        MyTraces(:,i,1) = Replay.TemplateTraces.(TraceNames{i}){whichreplay}(1:tracelength,1);
    end
    
    % common traces for both template and replays
    % Trial, TargetZone and Timestamps
    
    Trial = Replay.TemplateTraces.Trial{whichreplay}(1:tracelength,1);
    % Trial column has -ve values that indicate odorON periods
    % ignore them for plotting
    Trial(Trial<0) = 0;
    
    TZ_Up   = Replay.TemplateTraces.TargetZone{whichreplay}(1:tracelength,1);
    TZ_Low  = TZ_Up;
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
    
    timestamps = (1:tracelength)'/SampleRate;
    
    trials_per_replay = size(Replay.ReplayTraces.TrialIDs{whichreplay},1);
        
    % data (specific to open loop)
    for i = 1:numel(TraceNames)
        MyTraces(:,i,1+(1:trials_per_replay)) = Replay.ReplayTraces.(TraceNames{i}){whichreplay};
    end
        
    % Plotting the behavior
    if plotreplayfigs || savereplayfigs
        H1 = figure; % Lever traces
        H2 = figure; % Motor - odor location - traces
        
        for j = 1:(trials_per_replay+1)
            
            figure(H1);
            subplot(trials_per_replay+1,1,j);
            % PlotBehavior(timestamps,Lever(:,j),Sniffs(:,j),Licks(:,j),Rewards(:,j),Trial,TZ);
            PlotBehavior(timestamps,MyTraces(:,1,j),MyTraces(:,3,j),MyTraces(:,4,j),MyTraces(:,5,j),Trial,TZ);
            if j > trials_per_replay
                set(gca,'YLim',[-0.4 8],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
            else
                set(gca,'YLim',[-0.4 8],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))],...
                    'XTick',[]);
            end
            figure(H2);
            subplot(trials_per_replay+1,1,j);
            %PlotBehavior(timestamps,(Motor(:,j)+100)/40,[],[],[],Trial,(MotorTZ+100)/40);
            PlotBehavior(timestamps,(MyTraces(:,2,j)+100)/40,[],[],[],Trial,(MotorTZ+100)/40);
            if j > trials_per_replay
                set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
            else
                set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))],...
                    'XTick',[]);
            end
        end
        
        if savereplayfigs
            figure(H1);
            saveas(gcf,[MyFileName,'_ReplayBehavior.fig']);
            close(gcf);
            
            figure(H2);
            saveas(gcf,[MyFileName,'_ReplayMotor.fig']);
            close(gcf);
        end
    end
    
    %% Ephys
    PSTH = []; % dimensions: [trial x samples x units]
    if ~isempty(SingleUnits)
        if plotreplayfigs || savereplayfigs
            units_per_fig = 5;
            figure;
        end
        
        for i = 1:numel(whichUnits) % for every cell
            MyUnit = whichUnits(i);
            
            if plotreplayfigs || savereplayfigs
                if mod(i,units_per_fig)
                    FRplot = 2*mod(i,units_per_fig);
                else
                    FRplot = 2*units_per_fig;
                end
                Rasterplot = FRplot - 1;
                
                subplot(units_per_fig,2,Rasterplot);
                % plot the trial structure
                PlotBehavior(timestamps,[],[],[],[],Trial,[]);
                set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
                axis manual;
                hold on;
                
                subplot(units_per_fig,2,FRplot);
                % plot the trial structure
                PlotBehavior(timestamps,[],[],[],[],Trial,[]);
                %set(gca,'YLim',[-0.4 5.4],'YTick',[0 5],'TickDir','out','XLim',[0 round(timestamps(end))]);
                set(gca,'YLim',[0 25],'YTick',[0 50 100],'TickDir','out','XLim',[0 round(timestamps(end))]);
                axis manual;
                hold on;
            end
            
            % Get Spikes
            allspikes = SingleUnits(MyUnit).trialalignedspikes;
            MySpikeTimes = [];
            
            % first collate spikes for the original close loop stretch of replayed trials
            MyTrials = Replay.TemplateTraces.TrialIDs{whichreplay};
            offset = 0;
            for thisTrial = 1:numel(MyTrials)
                thisTrialSpikeTimes = allspikes(SingleUnits(MyUnit).trialtags == MyTrials(thisTrial));
                MySpikeTimes = [MySpikeTimes; thisTrialSpikeTimes + offset];
                offset = offset + TrialInfo.TraceDuration(MyTrials(thisTrial));
            end
            
            myPSTH = MakePSTH(MySpikeTimes',0,[0 ceil(offset*1000)],'downsample',SampleRate);
            PSTH(1,1:numel(myPSTH),i) = myPSTH;
            
            if plotreplayfigs || savereplayfigs
                % plot raster
                subplot(units_per_fig,2,Rasterplot);
                row_idx = 1;
                for eachspike = 1:numel(MySpikeTimes) % plot raster line
                    line([MySpikeTimes(eachspike) MySpikeTimes(eachspike)],...
                        [row_idx-1 row_idx],'Color','k');
                end
                
                % plot FR
                subplot(units_per_fig,2,FRplot);
                plot((1/SampleRate)*(1:numel(myPSTH)),myPSTH,'k');
            end
            
            % plot the replay spike times
            MyTrials = Replay.ReplayTrialIDs{whichreplay}(:,1);
            for thisTrial = 1:numel(MyTrials)
                OriginalSpikeTimes = allspikes(SingleUnits(MyUnit).trialtags == MyTrials(thisTrial));
                % these spike times are w.r.t. Trial start + start offset
                thisTrialSpikeTimes = NaN*OriginalSpikeTimes;
                thisTrialSpikeTags = NaN*OriginalSpikeTimes;
                
                % Raster: split the stretch of original SpikeTimes into trials within the long replay trial
                for subtrial = 1:size(TTLs.Replay{whichreplay,thisTrial},1)
                    tstart = TTLs.Replay{whichreplay,thisTrial}(subtrial,1) - TTLs.Replay{whichreplay,thisTrial}(1,1);
                    tstop  = TTLs.Replay{whichreplay,thisTrial}(subtrial,2) - TTLs.Replay{whichreplay,thisTrial}(1,1);
                    thisTrialSpikeTimes(find(OriginalSpikeTimes>=tstart & OriginalSpikeTimes<tstop)) = ...
                        OriginalSpikeTimes(find(OriginalSpikeTimes>=tstart & OriginalSpikeTimes<tstop)) ...
                        - tstop + Replay.ReplayChunks{whichreplay,thisTrial}(subtrial);
                    thisTrialSpikeTags(find(OriginalSpikeTimes>=tstart & OriginalSpikeTimes<tstop)) = subtrial;
                end
                
                % FR: Use the original spiketimes to get PSTH, split the PSTH 
                tempPSTH = MakePSTH(OriginalSpikeTimes',0,...
                    [0 ceil(TrialInfo.TraceDuration(MyTrials(thisTrial))*1000)],'downsample',SampleRate);
                % initialize a PSTH trace of the adequate length with the
                % correct indexing
                myPSTH = Replay.ReplayTraces{whichreplay,thisTrial}(:,7);
                % fill in the vector 
                for y = 1:numel(myPSTH)
                    if ~isnan(myPSTH(y))
                        myPSTH(y) = tempPSTH(myPSTH(y));
                    end
                end
                
                PSTH(1+thisTrial,1:numel(myPSTH),i) = myPSTH';
                
                if plotreplayfigs || savereplayfigs
                    % plot raster
                    subplot(units_per_fig,2,Rasterplot);
                    row_idx = thisTrial+1;
                    for eachspike = 1:numel(thisTrialSpikeTimes) % plot raster line
                        line([thisTrialSpikeTimes(eachspike) thisTrialSpikeTimes(eachspike)],...
                            [row_idx-1 row_idx],'Color',Plot_Colors('r'));
                    end
                    
                    % plot FR
%                     subplot(units_per_fig,2,FRplot);
%                     plot((1/SampleRate)*(1:numel(myPSTH)),myPSTH,'r');
                end
            end
            
            if plotreplayfigs || savereplayfigs
                
                % plot avg. FR for the replay trials
                subplot(units_per_fig,2,FRplot);
                plot((1/SampleRate)*(1:numel(myPSTH)),mean(squeeze(PSTH(:,:,i)),1),'r');
            
                title(['Unit# ',num2str(MyUnit)]);
                
                if mod(i,units_per_fig) == 0
                    if savereplayfigs
                        saveas(gcf,[MyFileName,'_MyUnits_',num2str(MyUnit/units_per_fig),'.fig']);
                        close(gcf);
                    end
                    figure;
                end
            end
        end
        
        if savereplayfigs
            saveas(gcf,[MyFileName,'_MyUnits_',num2str(MyUnit/units_per_fig),'.fig']);
            close(gcf);
        end
        
    end
    
    %% Outputs
    
    Physiology(whichreplay).PSTH = PSTH;
    
    Physiology(whichreplay).Correlation = PSTHCorr(PSTH,whichUnits);


end

end