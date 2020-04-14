function [] = PlotBehavior(timestamps,Lever,Sniffs,Licks,Rewards,Trial,TZ,timestampsReplay)

if nargin<8
    timestampsReplay = [];
end

%% Plots
% Trials
handles.trial_on_1 = fill(NaN,NaN,[.8 .8 .8]);
hold on;
handles.trial_on_1.EdgeColor = 'none';
handles.trial_on_2 = fill(NaN,NaN,[0.8941    0.9412    0.9020]);
%handles.trial_on_2 = fill(NaN,NaN,[.8 .8 .8]);
handles.trial_on_2.EdgeColor = 'none';
handles.trial_on_3 = fill(NaN,NaN,[0.8706    0.9216    0.9804]);
%handles.trial_on_3 = fill(NaN,NaN,[.8 .8 .8]);
handles.trial_on_3.EdgeColor = 'none';
handles.trial_on_4 = fill(NaN,NaN,[0.93    0.84    0.84]);
handles.trial_on_4.EdgeColor = 'none';

% whiten trial off periods
handles.trial_off = fill(NaN,NaN,[1 1 1]);
handles.trial_off.EdgeColor = 'none';

if ~isempty(Trial)
    [handles] = PlotToPatch_Trial(handles, Trial, timestamps, [0 5],1);
    [handles] = PlotToPatch_TrialOFFhack(handles, Trial, timestamps, [0 5],1);
end

% TargetZone
if ~isempty(TZ)
    handles.targetzone = fill(NaN,NaN,[1 1 0],'FaceAlpha',0.2);
    handles.targetzone.EdgeColor = 'none';

    [handles.targetzone] = PlotToPatch_TargetZone(handles.targetzone, TZ, timestamps);
end

% Lever
if ~isempty(Lever)
    handles.lever_plot = plot(NaN, NaN,'k');
    if isempty(timestampsReplay)
        set(handles.lever_plot,'XData',timestamps,'YData',Lever);
    else
        set(handles.lever_plot,'XData',timestampsReplay,'YData',Lever);
    end
end

% Sniffs
if ~isempty(Sniffs)
    handles.respiration_plot = plot(NaN, NaN,'color',Plot_Colors('r'));
    if isempty(timestampsReplay)
        set(handles.respiration_plot,'XData',timestamps,'YData',6.5+ 2*(Sniffs/max(Sniffs)));
    else
        set(handles.respiration_plot,'XData',timestampsReplay,'YData',6.5+ 2*(Sniffs/max(Sniffs)));
    end
end

% Rewards
if ~isempty(Rewards)
    handles.reward_plot = plot(NaN, NaN, 'color',Plot_Colors('t'),'Linewidth',1.25);
    if isempty(timestampsReplay)
        tick_timestamps =  timestamps(Rewards==1);
    else
        tick_timestamps =  timestampsReplay(Rewards==1);
    end
    tick_x = [tick_timestamps'; tick_timestamps'; ...
        NaN(1,numel(tick_timestamps))]; % creates timestamp1 timestamp1 NaN timestamp2 timestamp2..
    tick_x = tick_x(:);
    tick_y = repmat( [0; 6.5; NaN],...
        numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
    set(handles.reward_plot,'XData',tick_x,'YData',tick_y);
end

% Licks
if ~isempty(Licks)
    handles.lick_plot = plot(NaN, NaN, 'color',Plot_Colors('o'),'Linewidth',1); %licks
    if isempty(timestampsReplay)
        tick_timestamps =  timestamps(Licks==1);
    else
        tick_timestamps =  timestampsReplay(Licks==1);
    end
    tick_x = [tick_timestamps'; tick_timestamps'; ...
        NaN(1,numel(tick_timestamps))]; % creates timestamp1 timestamp1 NaN timestamp2 timestamp2..
    tick_x = tick_x(:);
    tick_y = repmat( [5.5; 6; NaN],...
        numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
    set(handles.lick_plot,'XData',tick_x,'YData',tick_y);
end

end
