%function [] = AdjustVideoBrightness()
%% Filepaths
vid_folder = '/Users/Priyanka/Desktop/temp/MP8_5/';
filetag = 'fc2_save_2017-03-09-141331-0003.avi';
timewindow = [-1 35]; % seconds
framerate = 50; % Hz
write_video = 0;

if write_video
    % video out
    writerObj = VideoWriter('test_video','MPEG-4');
    writerObj.FrameRate = framerate;
    open(writerObj);
end

% % load and display one frame
my_video = fullfile(vid_folder,filetag);
vidObj = VideoReader(my_video);

k = 1;
% load the entire clip first
while hasFrame(vidObj)
    s(k).cdata = readFrame(vidObj);
    k = k+1;
end

for i = 2:2:k-1
    frame = s(i-1).cdata;
    subplot(1,2,1); image(frame);
    frame = s(i).cdata;
    subplot(1,2,2); image(frame);
    
    if write_video
        f = getframe(h);
        writeVideo(writerObj,f);
    end
    
    if write_video
        % cleanup
        close(writerObj);
        delete(vidObj);
        delete(writerObj);
    end    
end