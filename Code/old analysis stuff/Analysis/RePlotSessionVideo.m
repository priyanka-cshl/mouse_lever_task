% recreate session plot in session-plotting style
% three different trial plots - for different odor
function [MyHandle] = RePlotSessionVideo(MyData, whichfig)

axes(whichfig);

%% initialize plots
handles.trial_on_1 = fill(NaN,NaN,[.8 .8 .8]);
hold on;
handles.trial_on_1.EdgeColor = 'none';
%handles.trial_on_2 = fill(NaN,NaN,[0.8941    0.9412    0.9020]);
handles.trial_on_2 = fill(NaN,NaN,[0.8 0.8 0.8]);
handles.trial_on_2.EdgeColor = 'none';
%handles.trial_on_3 = fill(NaN,NaN,[0.8706    0.9216    0.9804]);
handles.trial_on_3 = fill(NaN,NaN,[0.8 0.8 0.8]);
handles.trial_on_3.EdgeColor = 'none';
%handles.stimulus_plot = plot(NaN, NaN, 'color',Plot_Colors('r')); % target odor location
%handles.in_target_zone_plot = fill(NaN,NaN,Plot_Colors('r'));
%handles.in_target_zone_plot.EdgeColor = 'none';
%handles.in_reward_zone_plot = fill(NaN,NaN,Plot_Colors('o'));
%handles.in_reward_zone_plot.EdgeColor = 'none';

% handles.fake_target_plot = plot(NaN, NaN, 'color',[.7 .7 .7]);
handles.targetzone = fill(NaN,NaN,[1 1 0],'FaceAlpha',0.2);
handles.targetzone.EdgeColor = 'none';

% whiten trial off periods
handles.trial_off = fill(NaN,NaN,[1 1 1]);
handles.trial_off.EdgeColor = 'none';

handles.lever_DAC_plot = plot(NaN, NaN,'k','Linewidth',1); %lever rescaled
handles.respiration_plot = plot(NaN, NaN,'color',Plot_Colors('b'),'Linewidth',1.5); %respiration sensor

handles.reward_plot = plot(NaN, NaN, 'color',Plot_Colors('t'),'Linewidth',2); %rewards
handles.lick_plot = plot(NaN, NaN, 'color',Plot_Colors('r'),'Linewidth',1.25); %licks

set(gca,'YLim',[-0.4 7.7]);

MyHandle = get(gca);
%% Update plots

% lever positions, motor locations 
set(handles.lever_DAC_plot,'XData',MyData(:,1),'YData',MyData(:,4));
set(handles.respiration_plot,'XData',MyData(:,1),'YData',5.5+2*MyData(:,15)/max(MyData(:,15)));

%set(handles.stimulus_plot,'XData',MyData(:,1),'YData',...
%  1*(MyData(:,5)- 0) );

% trial_on
[handles] = PlotToPatch_Trial(handles, MyData(:,6), MyData(:,1), [0 5],1);
[handles] = PlotToPatch_TrialOFFhack(handles, MyData(:,6), MyData(:,1), [0 5],1);
[handles.targetzone] = PlotToPatch_TargetZone(handles.targetzone, MyData(:,2:3), MyData(:,1));

% in_target_zone, in_reward_zone
% [handles.in_target_zone_plot] = PlotToPatch(handles.in_target_zone_plot, MyData(:,7), MyData(:,1), [-1 0],1);
% [handles.in_reward_zone_plot] = PlotToPatch(handles.in_reward_zone_plot,  MyData(:,8), MyData(:,1), [-1 -0.2],1);

% rewards
tick_timestamps =  MyData(MyData(:,9)==1,1);
tick_x = [tick_timestamps'; tick_timestamps'; ...
    NaN(1,numel(tick_timestamps))]; % creates timestamp1 timestamp1 NaN timestamp2 timestamp2..
tick_x = tick_x(:);
tick_y = repmat( [-0.2; 5.7; NaN],...
    numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
set(handles.reward_plot,'XData',tick_x,'YData',tick_y);

% licks
tick_timestamps = MyData(MyData(:,10)==1,1);
tick_x = [tick_timestamps'; tick_timestamps'; ...
    NaN(1,numel(tick_timestamps))]; % creates timestamp1 timestamp1 NaN timestamp2 timestamp2..
tick_x = tick_x(:);
tick_y = repmat( [5.2; 5.7; NaN],...
    numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
set(handles.lick_plot,'XData',tick_x,'YData',tick_y);

% set(handles.fake_target_plot,'XData',TotalTime(indices_to_plot),'YData',...
%         handles.PerturbationSettings.Data(4) + 0*TotalTime(indices_to_plot));

