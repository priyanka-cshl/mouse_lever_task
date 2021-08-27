function [handles] = AlignVideoAndTraces_MovingBar_2()

write_video = 1;

%% Filepaths
vid_folder = '/Users/Priyanka/Desktop/temp/MP8_5/';
filetag = 'fc2_save_2017-03-09-141331-00';
startindex = 0; % video file start ID
stopindex = 5; % video file end ID
DataFile = fullfile('/Users/Priyanka/Desktop/temp/MP8/MP8_20170309_r1.mat');
timewindow = [-1 35]; % seconds
framerate = 50; % Hz

if write_video
    % video out
    writerObj = VideoWriter('test_video','MPEG-4');
    writerObj.FrameRate = framerate;
    open(writerObj);
end

%% Video display initializations
% display parameters
a = 0.5; % proportion occupied by the video image - choose between 0 and 1
margin = 0.5;
edge = 0.05;

% % load and display one frame
my_video = fullfile(vid_folder,[filetag,'0',num2str(startindex),'.avi']);
vidObj = VideoReader(my_video);
frame = readFrame(vidObj);
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

% initialize the data axes
handles.H2 = subplot(1,2,2);
% Read the data file
[MyData, MySettings] = ExtractSessionData(DataFile);
RePlotSessionVideo(MyData,handles.H2);
tstart = MySettings(find(diff(MySettings(2:end,16))==1)+3,1);
% why tstart(diff...) +3??  +1 because of diff, ++1 because of 2:end, +++1 - because it worked
datastart = find(MyData(:,1)>=tstart(1),1);
t0 = MyData(datastart,1);
tstart
offset = 0.4;
t0 = offset + t0;

frames_to_show = diff(timewindow)*framerate;
% when aligning to a specific stretch in the session, recalculate offset
tdesired = 172; % set to 0 if tdesired conincides with the start of video acquisition
if tdesired>0
    newoffset = tdesired - t0;
    frames_to_skip = round(newoffset*framerate);
    frames_per_video = 583;
    startindex = startindex + floor((frames_to_skip-1)/frames_per_video);
    stopindex = floor((frames_to_skip+frames_to_show-1)/frames_per_video);
    frames_remaining = mod(frames_to_skip,frames_per_video);
    t0 = tdesired;
    last_frame = mod(frames_to_skip+frames_to_show,frames_per_video);
else
    frames_remaining = 0;
end


% initialize video axes with one frame
handles.H1 = subplot(1,2,1);
axes(handles.H1);
handles.H1.LineWidth = 2;
handles.frame = image(frame,'parent',handles.H1);
set(handles.H1,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H1,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
set(handles.H1, 'position', [margin/2, edge*2 , a, a*ratio*d(2)/d(1)]); % left, bottom, width, height relative to the bottom left corner

%set(handles.H2,'position',[a+margin, margin, 1-a-1.5*margin, a*ratio*d(2)/d(1)]);
set(handles.H2, 'position', [-0.2+margin/2, 0.7, 0.9, 0.2]);
set(handles.H2,'XTick',handles.H2.XLim(1):2:handles.H2.XLim(2),'XTickLabel',num2str([(handles.H2.XLim(1):2:handles.H2.XLim(2))-handles.H2.XLim(1)]'))
set(handles.H2,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
handles.H2.XLim = t0 + timewindow;
handles.H2.FontSize = 12;
handles.H2.FontWeight = 'bold';
set(handles.H2,'YTick',[0 5],'YTickLabel',{'min' 'max'},'TickDir','out','Box','off');
handles.H2.TickLength(1) = 0.005;
% handles.H2.Position(2) = 0.4;
% handles.H2.Position(4) = 0.4;

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
%handles.H3.FontWeight = 'bold';

% % add another axes to mark the targetzone boundaries
zonehalfwidth = 0.0625*handles.H1.Position(3);
zoneheight = 0.06;
handles.H4 = axes;
handles.H4.Position = handles.H1.Position;
handles.H4.Position(1) = handles.H1.Position(1) + (handles.H1.Position(3))/2 - zonehalfwidth;
handles.H4.Position(2) = handles.H1.Position(2) - zoneheight - 0.001;
handles.H4.Position(3) = 2*zonehalfwidth;
%handles.H4.Position(1) = handles.H4.Position(1) + 0.025;

set(gca,'Color',[0.8 0.8 0.8]);
handles.H4.Position(3) = 2*zonehalfwidth;
handles.H4.Position(4) = zoneheight;
set(handles.H4,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H4,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
handles.H4.YColor = 'none';
handles.H4.XColor = 'none';

%handles.lim1 = line(min(handles.H4.XLim)+[0 0],get(gca,'YLim'),'color','w','Linewidth',6);
%handles.lim2 = line(max(handles.H4.XLim)+[0 0],get(gca,'YLim'),'color','w','Linewidth',6);

% load the whole set of frames first into a massive struct
Allframes = [];

% list of corrupt frames
corruptframes = [3 97; 3 306; 3 442; 4 69; 4 77; 4 195; 4 424; 5 459];

m = 1;
for num = startindex:1:stopindex % stream through each video
    
    if num<10
        my_video = fullfile(vid_folder,[filetag,'0',num2str(num),'.avi']);
    else
        my_video = fullfile(vid_folder,[filetag,num2str(num),'.avi']);
    end
    
    vidObj = VideoReader(my_video);
    % load the entire clip first
    k = 1;
    while hasFrame(vidObj)
        % read the frame
        s(k).cdata = readFrame(vidObj);
        k = k+1;
        
        % decide whether to add to stack or not
        if num > startindex && num < stopindex
            % duplicate old frame if frame is known to be corrupt
            if ismember([num k-1],corruptframes,'rows')
                Allframes(m).cdata = s(k-2).cdata; % duplicate previous frame
            else
                Allframes(m).cdata = s(k-1).cdata;
            end
            m = m+1;
        elseif num == startindex && k>frames_remaining
            Allframes(m).cdata = s(k-1).cdata;
            m = m+1;
        elseif num == stopindex && k<last_frame
            Allframes(m).cdata = s(k-1).cdata;
            m = m+1;
        end
        
    end
end

for i = 1:m-1;
    axes(handles.H1);
    handles.frame.CData = Allframes(i).cdata;
    
    t0 = t0 + (1/framerate);
    handles.bar.XData = [t0 t0];
    pause(1/framerate);
    
    % encoding of trial state
    t1 = find(abs(MyData(:,1)-t0)==min(abs(MyData(:,1)-t0)),1);
    if MyData(t1,6)>0
        if MyData(t1,7)>0
            handles.H4.Color = [245 121 0]./255;
        else
            handles.H4.Color = [239 41 41]./255;
        end
    else
        handles.H4.Color = [0.8 0.8 0.8];
    end
    
    if write_video
        f = getframe(h);
        writeVideo(writerObj,f);
    end
    
    %         border=round(edge*square);
    %         % to make sure axes are not clipped
    %
    %         max(1,round(square*(1-margin-(ratio)*a))-border)
    %         min(square,round(square*(1.0-margin))+border)
    %
    %         f.cdata=f.cdata(max(1,round(square*(1-margin-(ratio)*a))-border):...
    %         min(square,round(square*(1.0-margin))+border),:,:);
    
    %crop the frames
    %f contains the square frame, minus the menu
    %e.g. on a 1440*900 monitor f.cdata is a 801*801 Y,X vector w/ position
    %relative to the top left corner
end

if write_video
    % cleanup
    close(writerObj);
    delete(vidObj);
    delete(writerObj);
end
end



