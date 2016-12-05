function get_image(h,hObject)
global mycam
display('New image');
h.cam_image = snapshot(mycam);
%image(h.cam_image,'parent',h.cam_axes);
guidata(hObject, h);