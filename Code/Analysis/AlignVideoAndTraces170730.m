function [handles] = AlignVideoAndTraces170730(write_video)

if nargin<1
    write_video = 0;
end

%% defaults
timewindow = [-1 25]; % seconds
video_framerate = 50; % Hz
data_samplerate = 500;
framerate = video_framerate*(data_samplerate/1000); % 25; % w.r.t to sample rate of 500 Hz, actual rate = 50Hz
%frames_to_show = diff(timewindow)*framerate;
frames_to_show = max(timewindow)*framerate;

%% FilePaths
vid_folder = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/Movies/Raw/PM27_170728_t5';
filetag = 'fc2_save_2017-07-28-174142-'; %0000';
DataFile = fullfile('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/PM27/PM27_20170728_r1.mat');

%% Read the Data File - correct target zone mismatch
[MyData, MySettings, TargetZones, FakeTargetZones] = ExtractSessionData(DataFile);
[~, ~, TrialInfo, TargetZones] = ChunkUpTrials(MyData, TargetZones, FakeTargetZones);
[TrialInfo, MyData] = FixTargetZoneAssignments(MyData,TrialInfo,TargetZones,MySettings);
[AllTFs] = GetAllTransferFunctions(MySettings, TargetZones);

% time at which save camera was turned on
%tstart = MySettings(find(diff(MySettings(1:end,16))==1)+1,1);
updateAT = MySettings(find(diff(MySettings(1:end,16))==1)+1,1); % +1 because of diff
tstart = TrialInfo.Timestamps(find(TrialInfo.Timestamps(:,1)>updateAT(1),1)-1,2); % time of previous trial off
datastart = find(MyData(:,1)>=tstart(1),1);
t0 = MyData(datastart,1);
base_offset = 0.3; % to allow for delays in matlab to arduino communication
t0 = base_offset + t0;
time_desired = 160; 
%frame_offset = round((time_desired - t0)*video_framerate) - 22;
frame_offset = round((time_desired - t0)*framerate) - 22;
t0 = time_desired;
 
%% Video related initializations
if write_video
    writerObj = VideoWriter('test_video','MPEG-4');
    writerObj.FrameRate = framerate;
    open(writerObj);
end

%% Video display related initializations
% display parameters
a = 0.5; % proportion occupied by the video image - choose between 0 and 1
margin = 0.5;
edge = 0.05;

% load and display one frame
frame = imread(fullfile(vid_folder,[filetag,'0000.jpg']));
frame = imresize(frame,0.5); % half the image size
ratio = size(frame,1)/size(frame,2);

% to get the resolution of the monitor minus the menu elements
t = figure('name','video');
set(t, 'Units', 'Normalized', 'OuterPosition', [0 0 0.75 1]);
f = getframe(t);
d = size(f.cdata);
% override figure height
%d(1) = 500;
close (gcf);
pause(0.5);

%% Actual figure combining video and traces
h = figure('position', [1 1 d(2) d(1)], 'color', 'w');
pause(0.5);

% initialize the data axes and plot the session data
handles.H2 = subplot(1,2,2);
RePlotSessionVideo(MyData,handles.H2);

% initialize video axes with one frame
handles.H1 = subplot(1,2,1);
axes(handles.H1);
handles.H1.LineWidth = 2;
handles.frame = imagesc(frame,'parent',handles.H1);
colormap('gray');
set(handles.H1,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H1,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
set(handles.H1, 'position', [margin/2, edge*2 , a, a*ratio*d(2)/d(1)]); % left, bottom, width, height relative to the bottom left corner

%set(handles.H2,'position',[a+margin, margin, 1-a-1.5*margin, a*ratio*d(2)/d(1)]);
set(handles.H2, 'position', [-0.2+margin/2, 0.7, 0.85, 0.2]);
set(handles.H2,'XTick',handles.H2.XLim(1):2:handles.H2.XLim(2),'XTickLabel',num2str([(handles.H2.XLim(1):2:handles.H2.XLim(2))-handles.H2.XLim(1)]'))
set(handles.H2,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
handles.H2.XLim = t0 + timewindow;
handles.H2.FontSize = 12;
handles.H2.FontWeight = 'bold';
set(handles.H2,'YTick',[0 5],'YTickLabel',{'min' 'max'},'TickDir','out','Box','off');
handles.H2.TickLength(1) = 0.005;

% initialize another axes object to plot the timestamp bar
handles.H3 = axes;
handles.H3.Position = handles.H2.Position;
handles.H3.Position(2) = handles.H3.Position(2) - 0.005;
handles.H3.Position(4) = handles.H3.Position(4) + 0.01;
axes(handles.H3);
set(gca, 'Color', 'none');
handles.H3.YLim = handles.H2.YLim;
handles.H3.XLim = t0 + timewindow;
set(handles.H3,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H3,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual','TickDir','out','Box','off');
handles.bar = line([t0 t0],handles.H3.YLim,'color',[239 41 41]./256,'LineWidth',2);
handles.H3.FontSize = 14;
handles.H3.TickLength(1) = 0.005;
handles.H3.YColor = 'none';
handles.H3.XColor = 'none';

% add two more axes to display transfer function and the motor location
handles.H5 = axes;
handles.H5.Position = handles.H2.Position;
handles.H5.Position(1) = handles.H2.Position(1) + handles.H2.Position(3)+margin/20;
handles.H5.Position(3) = 0.02;
YLimfactor = handles.H2.Position(4)/(handles.H2.YLim(2) - handles.H2.YLim(1));
handles.H5.Position(2) = handles.H5.Position(2) + YLimfactor*abs(handles.H2.YLim(1));
handles.H5.Position(4) = YLimfactor*5;
handles.TF_plot = imagesc(((-50:1:50)')/50,[-1 1]);
colormap(handles.H5, brewermap([17],'rdbu'));
axis off tight
set(handles.H5,'YLim',[0 100]);

handles.H6 = axes;
handles.H6.Position = handles.H5.Position;
handles.H6.Position(1) = handles.H6.Position(1) + handles.H5.Position(3);
handles.motor_location = plot([1],[2],'r<','MarkerFaceColor','k','MarkerEdgeColor','k');
axis off tight
set(handles.H6,'YLim',[0 100]);
set(handles.H6, 'Color', 'none');

% % add another axes to mark the targetzone boundaries
zonehalfwidth = 0.0625*handles.H1.Position(3);
zoneheight = 0.06;
handles.H4 = axes;
handles.H4.Position = handles.H1.Position;
handles.H4.Position(1) = handles.H1.Position(1) + (handles.H1.Position(3))/2 - zonehalfwidth;
handles.H4.Position(2) = handles.H1.Position(2) - zoneheight - 0.001;
handles.H4.Position(3) = 2*zonehalfwidth;

set(gca,'Color',[0.8 0.8 0.8]);
handles.H4.Position(3) = 2*zonehalfwidth;
handles.H4.Position(4) = zoneheight;
set(handles.H4,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H4,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual','Box','on');
handles.H4.Color = [1 1 1];

% get current TF
TrialNum = find(TrialInfo.Timestamps(:,1)>=t0,1);
MyTF = AllTFs(TrialInfo.TargetZoneType(TrialNum,:),:);
handles.TF_plot.CData = MyTF';

trialstate = [0 0];
for i = 1:frames_to_show;
    axes(handles.H1);
    frameID = num2str(((i+frame_offset)/10000)+0.00001);
    frame = imread(fullfile(vid_folder,[filetag,frameID(3:end-1),'.jpg']));
    handles.frame.CData = imresize(frame,0.5);
    
    t0 = t0 + (1/framerate);
    handles.bar.XData = [t0 t0];
    pause(1/framerate);
    
    % encoding of trial state
    t1 = find(abs(MyData(:,1)-t0)==min(abs(MyData(:,1)-t0)),1);
    if MyData(t1,6)>0
        trialstate(2) = 1;
        if mode(MyData(t1-19:t1,7))>0
            %handles.H4.Color = [0.8 0.8 0.8];
            %handles.H4.Color = [1 1 0];
            handles.H4.Color = [242 234 178]./255;
        else
            handles.H4.Color = [0.8 0.8 0.8];
            %handles.H4.Color = [239 41 41]./255;
        end
    else
        trialstate(2) = 0;
        %handles.H4.Color = [0.8 0.8 0.8];
        handles.H4.Color = [1 1 1];
    end
    
    % if trial just went off
    if (trialstate(1)-trialstate(2))==1
        TrialNum = find(TrialInfo.Timestamps(:,1)>=t0,1);
        MyTF = AllTFs(TrialInfo.TargetZoneType(TrialNum,:),:);
        handles.TF_plot.CData = MyTF';
    end
    
    % Show motorlocation
    motor_location = MyData(t1,13);
    [~,foo] = min(handles.TF_plot.CData);
    MyMap = handles.TF_plot.CData;
    MyMap(foo:end,1) = -1*MyMap(foo:end,1);
    [~,idx] = min(abs(MyMap-motor_location/80));
    idx = 100 - idx;
    handles.motor_location.YData = idx;
    
    trialstate(1) = trialstate(2);
    
    if write_video
        f = getframe(h);
        writeVideo(writerObj,f);
    end
end

if write_video
    % cleanup
    close(writerObj);
    delete(vidObj);
    delete(writerObj);
end

end



