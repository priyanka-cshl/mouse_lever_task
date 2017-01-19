adaptor_name = 'pointgrey';
info = imaqhwinfo(adaptor_name); % get device ID
dev_info = imaqhwinfo(adaptor_name,info.DeviceIDs{1});
vid = videoinput('pointgrey',1,dev_info.SupportedFormats{12});
%vid = videoinput(adaptor_name,1);

% Set video input object properties for this application.
%vid.TriggerType = 'immediate';
triggerconfig(vid, 'immediate');
% vid.TriggerRepeat = 10;
%vid.FrameGrabInterval = 5;

% 
% % % Set value of a video source object property.
vid_src = getselectedsource(vid);
% % vid_src.Tag = 'motion detection setup';
% 
% Create a figure window.
figure; 

% Start acquiring frames.
start(vid)
% 
% % Calculate difference image and display it.
while(vid.FramesAvailable < 1)
end
while(vid.FramesAvailable >= 1)
    data = getdata(vid,1); 
%     data = getdata(vid,2); 
%     diff_im = imabsdiff(data(:,:,:,1),data(:,:,:,2));
%     imshow(diff_im);
    imshow(data);
    drawnow     % update figure window
end
% 
stop(vid)