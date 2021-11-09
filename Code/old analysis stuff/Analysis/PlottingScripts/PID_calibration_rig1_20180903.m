% PID analysis script for plotting calibration data acquired on mouselever Rig-1

% first set, cycles through all 4 odors (blank, IAA, ET, EB)
% all odors loaded ~5ml in the vial, input flow ~0.15lpm,
% only 1 dilution ~15lpm (~1:100)
% PID at high flow, high gain, ~12.5 mm away from the manifold
% odor build-up time before session start = 10 minutes

global DataRoot;
DataRoot = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/';
colormaptag = 'Blues';
mycolors = brewermap(150,colormaptag);
set(groot,'defaultAxesColorOrder',mycolors);
mycolors = flipud(mycolors);

%% session 1 : 50, 450, 3500, 100, 500, 400 ms
% motor settle, pre-odor, odor, air-purge, post-odor, ITI
% 150 reps each

FileName = 'Calibrations_20180903_r0.mat';
[DataOut] = AnalyzeOpenLoop(FileName, 'PID');
[AllTraces] = PlotOpenLoopPID(DataOut);

figure(1);
for i = 1:4
    subplot(2,4,i);
    timestamps = 2*(1:size(AllTraces.(['Odor',num2str(i)]).Location0,2)); % 500Hz sampling rate
    plot(timestamps, AllTraces.(['Odor',num2str(i)]).Location0');
    set(gca,'TickDir','Out','YLim',[-0.5 1.5],'XTick',[]);
    hold on;
    line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
    line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');
    if i ~= 1
        set(gca,'YTick',[]);
    end
end

for i = 1:4
    % plot averages of 10 traces
    subplot(2,4,i+4); hold all
    for j = 1:10:140
        mytrace = mean(AllTraces.(['Odor',num2str(i)]).Location0(j:j+9,:));
        plot(timestamps, mytrace, 'color', mycolors(j+9,:), 'Linewidth' ,1);
    end
    mytrace = mean(AllTraces.(['Odor',num2str(i)]).Location0(141:end,:));
    plot(timestamps, mytrace, 'color', mycolors(j+9,:), 'Linewidth' ,1);
    
    set(gca,'TickDir','Out','YLim',[-0.5 1.5]);
    line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
    line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');
    
    if i ~= 1
        set(gca,'YTick',[]);
    end
    
end

%% session 2: same settings as above
% 50 reps of odor 2 only

FileName = 'Calibrations_20180903_r1.mat';
[DataOut] = AnalyzeOpenLoop(FileName, 'PID');
[AllTraces] = PlotOpenLoopPID(DataOut);

figure(2); subplot(2,4,3);
timestamps = 2*(1:size(AllTraces.Odor3.Location0,2)); % 500Hz sampling rate
plot(timestamps, AllTraces.Odor3.Location0');
set(gca,'TickDir','Out','YLim',[-0.5 1.5],'XTick',[],'YTick',[]);
hold on;
line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');

% plot averages of 10 traces
subplot(2,4,7); hold on
for j = 1:10:40
    mytrace = mean(AllTraces.Odor3.Location0(j:j+9,:));
    plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);
end
mytrace = mean(AllTraces.Odor3.Location0(41:end,:));
plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);

set(gca,'TickDir','Out','YLim',[-0.5 1.5],'YTick',[]);
line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');

%% session 3: same settings as above
% 50 reps of odor 1 only

FileName = 'Calibrations_20180903_r2.mat';
[DataOut] = AnalyzeOpenLoop(FileName, 'PID');
[AllTraces] = PlotOpenLoopPID(DataOut);

figure(2); subplot(2,4,2);
timestamps = 2*(1:size(AllTraces.Odor2.Location0,2)); % 500Hz sampling rate
plot(timestamps, AllTraces.Odor2.Location0');
set(gca,'TickDir','Out','YLim',[-0.5 1.5],'XTick',[],'YTick',[]);
hold on;
line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');

% plot averages of 10 traces
subplot(2,4,6); hold on
for j = 1:10:40
    mytrace = mean(AllTraces.Odor2.Location0(j:j+9,:));
    plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);
end
mytrace = mean(AllTraces.Odor2.Location0(41:end,:));
plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);

set(gca,'TickDir','Out','YLim',[-0.5 1.5],'YTick',[]);
line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');

%% session 4: same settings as above
% 50 reps of odor 3 only

FileName = 'Calibrations_20180903_r3.mat';
[DataOut] = AnalyzeOpenLoop(FileName, 'PID');
[AllTraces] = PlotOpenLoopPID(DataOut);

figure(2); subplot(2,4,4);
timestamps = 2*(1:size(AllTraces.Odor4.Location0,2)); % 500Hz sampling rate
plot(timestamps, AllTraces.Odor4.Location0');
set(gca,'TickDir','Out','YLim',[-0.5 1.5],'XTick',[],'YTick',[]);
hold on;
line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');

% plot averages of 10 traces
subplot(2,4,8); hold on
for j = 1:10:40
    mytrace = mean(AllTraces.Odor4.Location0(j:j+9,:));
    plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);
end
mytrace = mean(AllTraces.Odor4.Location0(41:end,:));
plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);

set(gca,'TickDir','Out','YLim',[-0.5 1.5],'YTick',[]);
line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');


%% session 5 : 50, 450, 3500, 200, 500, 400 ms
% motor settle, pre-odor, odor, air-purge, post-odor, ITI
% 50 reps each
% 200 ms purge

FileName = 'Calibrations_20180903_r4.mat';
[DataOut] = AnalyzeOpenLoop(FileName, 'PID', 1); % need to delete first trial
[AllTraces] = PlotOpenLoopPID(DataOut);

figure(3);
for i = 1:4
    subplot(2,4,i);
    timestamps = 2*(1:size(AllTraces.(['Odor',num2str(i)]).Location0,2)); % 500Hz sampling rate
    plot(timestamps, AllTraces.(['Odor',num2str(i)]).Location0');
    set(gca,'TickDir','Out','YLim',[-0.5 1.5],'XTick',[]);
    hold on;
    line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
    line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');
    if i ~= 1
        set(gca,'YTick',[]);
    end
end

for i = 1:4
    % plot averages of 10 traces
    subplot(2,4,i+4); hold on
    for j = 1:10:40
        mytrace = mean(AllTraces.(['Odor',num2str(i)]).Location0(j:j+9,:));
        plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);
    end
    mytrace = mean(AllTraces.(['Odor',num2str(i)]).Location0(41:end,:));
    plot(timestamps, mytrace, 'color', mycolors(3*(j+9),:), 'Linewidth' ,1);
    
    set(gca,'TickDir','Out','YLim',[-0.5 1.5]);
    line([500, 500],[-0.5 1.5],'color','k','LineStyle',':');
    line([700, 700],[-0.5 1.5],'color','k','LineStyle',':');
    
    if i ~= 1
        set(gca,'YTick',[]);
    end
    
end








