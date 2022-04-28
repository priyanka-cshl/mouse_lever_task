%need to implement:
%way to choose frame 2 
%way to rotate input 1
%way to limit value of a (calculate?)
%
VID = VideoReader('input_video','Tag','My reader object')
writerObj = VideoWriter('output_video','MPEG-4');
% default: 'MPEG-4'. For other options see 'doc Videowriter'
% MPEG-4 files require frame dimensions that are divisible by two. 
% If the input frame width for an MPEG-4 file is not an even number,
% VideoWriter pads the frame with a column of black pixels along the right side.
writerObj.FrameRate = 24;
%specify the FPS of the output video
open(writerObj);

skipcolumns=0
skiprows=0;

DATA = csvread('datafile.csv',skiprows,skipcolumns);
XX=DATA(:,1);
YY=DATA(:,2);

prompt = 'Initial frame #?';
bgn = input(prompt)

prompt = 'How many frames? (press enter to process whole video)';
nframes = input(prompt)

prompt = 'Skip first n frames';
skip = input(prompt)


prompt = 'Data Aqc. Rate (Hz)?';
daqrate = input(prompt)

%Do we want the image to be rotated?
prompt = 'rotate? (0=0?,1=90? CCW, 2=180?,3=270? CCW)';
rotate = input(prompt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%parameters that control how each frame looks like:%
a=0.3;
%choose between 0 and 1, see figure below:
margin=0.05;
edge=0.05;

%    plotting a wide image might look like this:
%    ____________________________________________   
%   |                                            |       ^
%   |                                            |       |
%   |                                            |       | 
%   |                                            |       |
%   |                                            |       |
%   |                                            |       |
%   |                                            |       |
%   |                      1                     |       |
%   |<------------------------------------------>|       |  1
%   |____________________________________________|       |
%   |                ? edge                      |       |
%   |________________V_____   ___________________|       |
%   |                      | |                   |       |
%   |                      |m|                   |       |
%   |        IMAGE         |a|      PLOT         |       |
%   |<-------------------->|r|<----------------->|       |
%   |          a           |g|    1-a-margin     |       |
%   |                      |i|                   |       |
%   |                      |n|                   |       |
%   |______________________|_|___________________|       |
%   |                ?edge                       |       |
%   |________________V___________________________|       V
%
%
%   plotting a tall image might look like this:
%    ____________________________________________  
%   |                                            |       ^
%   |                      1                     |       | 
%   |<------------------------------------------>|       |
%   |                                            |       |
%   |____________________________________________|       |
%   |                   edge  ?                  |       |
%   |_______________   _______V__________________|       |           
%   |               | |                          |       |
%   |               | |                          |       |  1
%   |               |m|                          |       |
%   |               |a|                          |       |
%   |               |r|                          |       |
%   |               |g|                          |       |
%   |    IMAGE      |i|          PLOT            |       |
%   |<------------->|n|<------------------------>|       |
%   |      a        | |       1-a-margin         |       |
%   |               | |                          |       | 
%   |               | |                          |       |
%   |_______________|_|__________________________|       |
%   |                  edge ?                    |       |
%   |_______________________V____________________|       V


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fps=VID.FrameRate;
totalframes=VID.NumberOfFrames;

rate=daqrate/fps;

Xdata_1=[];
Ydata_1=[];
Xdata_2=[];
Ydata_2=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frameA=read(VID,bgn+skip+1); 
frameB = imrotate(frameA,rotate*90);
imshow(frameB);
title('press and hold shift to get a square')

rect = getrect(gcf)
x=[rect(1) rect(1)+rect(3)];
y=[rect(2) rect(2)+rect(4)];

ratio =(y(2)-y(1))/(x(2)-x(1))
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%to figure out the maximum number of frames we can read in
total=size(nframes)
total=total(1);

j = bgn+skip+1;
datasize=size(XX);
datasize=datasize(1);
while((j<totalframes) && (round((j-bgn)*rate)<datasize))
    j=j+1   
end    

maxframes=j-(bgn+skip+1)-1

if(total==0)
    %pick the maximum frame#
    nframes=maxframes;
else(total>0)
    %pick the user frame number if it doesn't exceed max frame#
    nframes=min(nframes,maxframes);    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%to get the resolution of your monitor minus menu elements
t=figure(1)
set(t,'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

j=bgn+skip+1;
frame=read(VID,j); 
f=getframe(t);
d=size(f.cdata)
Yres=d(1)
Xres=d(2)

square=min(Xres,Yres)

close all;
pause(0.5);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%to get the right xlim & ylim

for j = (bgn+skip+1) : bgn+skip+nframes+1
    j
    Xdata_1(end+1)=XX(round((j-bgn)*rate));
    Ydata_1(end+1)=YY(round((j-bgn)*rate));    
end

u=figure(1);
plot(Xdata_1,Ydata_1);
XLIM=get(gca,'xlim') 
YLIM=get(gca,'ylim')
close all;
pause(0.5);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

h=figure('position',[1 1 square square],'color','w');
pause(0.5);

for k = (bgn+skip+1) : bgn+skip+nframes+1
    tic
    AA=subplot(1,2,1);
    set(AA,'position',[0, margin,a,ratio*(a)]);
    %left,bottom,width,height relative to the bottom left corner

    frame=read(VID,k); 
    frame = imrotate(frame,rotate*90);
    imshow(frame(y(1):y(2),x(1):x(2),:));

    Xdata_2(end+1)=XX(round((k-bgn)*rate));
    Ydata_2(end+1)=YY(round((k-bgn)*rate));

    BB=subplot(1,2,2);
    set(BB,'position',[a+margin,margin, 1-a-1.5*margin,ratio*a]);
    
    %left,bottom,width,height relative to the bottom left corner

    hold on
    plot(Xdata_1,Ydata_1,'LineWidth',2,'LineStyle',':','Color','blue')
    plot(Xdata_2,Ydata_2,'LineWidth',2.5,'LineStyle','-','Color','red')
    ylim=YLIM;
    xlim=XLIM;
    ylabel('Ylabel','FontSize',12,'FontWeight','bold','Color','r')   
    xlabel('Xlabel','FontSize',12,'FontWeight','bold','Color','r')  
    title('Title')    
    hold off

%     pause(0.01);
    %to reduce flicker in movie - you may or may not need this
    f=getframe(h);
    
    border=round(edge*square);
    %to make sure axes are not clipped

    max(1,round(square*(1-margin-(ratio)*a))-border)
    min(square,round(square*(1.0-margin))+border)
    
    f.cdata=f.cdata(max(1,round(square*(1-margin-(ratio)*a))-border):...
        min(square,round(square*(1.0-margin))+border),:,:);

    %crop the frames
    %f contains the square frame, minus the menu
    %e.g. on a 1440*900 monitor f.cdata is a 801*801 Y,X vector w/ position 
    %relative to the top left corner
    
    writeVideo(writerObj,f);

    toc    
end

%left,bottom,width,height
 
close(writerObj)
delete(VID)
delete(writerObj)
close all

