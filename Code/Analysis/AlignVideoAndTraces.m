function [handles] = AlignVideoAndTraces()

write_video = 0;

%% Filepaths
vid_folder = '/Users/Priyanka/Desktop/temp/MP8_5/';
filetag = 'fc2_save_2017-03-09-141331-000';
startindex = 0; % video file start ID
stopindex = 5; % video file end ID
DataFile = fullfile('/Users/Priyanka/Desktop/temp/MP8/MP8_20170309_r0.mat');
timewindow = 5; % seconds

if write_video
    % video out
    writerObj = VideoWriter('test_video','MPEG-4');
    writerObj.FrameRate = 50;
    open(writerObj);
end

%% Video display initializations
% display parameters
a = 0.4; % proportion occupied by the image - choose between 0 and 1
margin = 0.1;
edge = 0.05;

% % load and display one frame
my_video = fullfile(vid_folder,[filetag,num2str(startindex),'.avi']);
vidObj = VideoReader(my_video);
frame = readFrame(vidObj);
ratio = size(frame,1)/size(frame,2);

% to get the resolution of the monitor minus the menu elements
t = figure(1);
set(t, 'Units', 'Normalized', 'OuterPosition', [0 0 0.75 1]);
f = getframe(t);
d = size(f.cdata);
% Yres = d(1);
% Xres = d(2);
close all;
pause(0.5);

%% Actual figure combining video and traces
h = figure('position', [1 1 d(2) d(1)], 'color', 'w');
pause(0.5);

% initialize the data axes
handles.H2 = subplot(1,2,2);
% Read the data file
[MyData, MySettings] = ExtractSessionData(DataFile);
RePlotSessionVideo(MyData,handles.H2);
tstart = MySettings(find(diff(MySettings(2:end,16))==1)+1,1);
datastart = find(MyData(:,1)>=tstart(1),1);
t0 = MyData(datastart,1);
offset = 0 + 0.2;
t0 = offset + t0;
set(handles.H2,'position',[a+margin, margin, 1-a-1.5*margin, a*ratio*d(2)/d(1)]);
set(handles.H2,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H2,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
handles.H2.XLim = t0 + timewindow*[-1 1];
handles.H2.FontSize = 14;
handles.H2.FontWeight = 'bold';
set(handles.H2,'YTick',[0 5],'YTickLabel',{'min' 'max'},'TickDir','out');
handles.H2.Position(2) = 0.33;
handles.H2.Position(4) = 0.33;

% initialize video axes with one frame
handles.H1 = subplot(1,2,1);
axes(handles.H1);
handles.H1.LineWidth = 2;
handles.frame = image(frame,'parent',handles.H1);
set(handles.H1,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H1,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
set(handles.H1, 'position', [margin/2, margin , a, a*ratio*d(2)/d(1)]); % left, bottom, width, height relative to the bottom left corner

% initialize another axes object to plot the timestamp bar
handles.H3 = axes;
handles.H3.Position = handles.H2.Position;
axes(handles.H3);
set(gca, 'Color', 'none');
handles.H3.YLim = handles.H2.YLim;
handles.H3.XLim = [-timewindow timewindow];
set(handles.H3,'XTick',[-timewindow 0 timewindow],'TickDir','out');
set(handles.H3,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
line([0 0],handles.H3.YLim,'color','k','LineStyle','--');
handles.H3.FontSize = 14;
handles.H3.FontWeight = 'bold';

% % add another axes to mark the targetzone boundaries
zonehalfwidth = 0.07*handles.H1.Position(3);
zoneheight = 0.01;
handles.H4 = axes;
handles.H4.Position = handles.H1.Position;
handles.H4.Position(1) = handles.H1.Position(1) + (handles.H1.Position(3)-handles.H1.Position(1))/2 - zonehalfwidth;
handles.H4.Position(2) = handles.H1.Position(2) - zoneheight;
handles.H4.Position(3) = 2*zonehalfwidth;
handles.H4.Position(1) = handles.H4.Position(1) + 0.025;

set(gca,'Color','r');
handles.H4.Position(3) = 2*zonehalfwidth;
handles.H4.Position(4) = zoneheight;
set(handles.H4,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.H4,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
handles.H4.YColor = 'none';
handles.H4.XColor = 'none';

for num = startindex%:1:stopindex
    my_video = fullfile(vid_folder,[filetag,num2str(num),'.avi']);
    vidObj = VideoReader(my_video);
    k = 1;  
    while hasFrame(vidObj)
        s(k).cdata = readFrame(vidObj);
        k = k+1;
    end
    for i = 1:k-1
        axes(handles.H1);
        handles.frame.CData = s(i).cdata;
        t0 = t0 + (1/50);
        handles.H2.XLim = t0 + timewindow*[-1 1];;
        pause(1/10);
        
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
    
       % 


        
    end
end
 
if write_video
    % cleanup
    close(writerObj)
    delete(vidObj)
    delete(writerObj)
end
end



