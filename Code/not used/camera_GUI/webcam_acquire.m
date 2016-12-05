function varargout = webcam_acquire(varargin)
% WEBCAM_ACQUIRE MATLAB code for webcam_acquire.fig
%      WEBCAM_ACQUIRE, by itself, creates a new WEBCAM_ACQUIRE or raises the existing
%      singleton*.
%
%      H = WEBCAM_ACQUIRE returns the handle to a new WEBCAM_ACQUIRE or the handle to
%      the existing singleton*.
%
%      WEBCAM_ACQUIRE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WEBCAM_ACQUIRE.M with the given input arguments.
%
%      WEBCAM_ACQUIRE('Property','Value',...) creates a new WEBCAM_ACQUIRE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before webcam_acquire_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to webcam_acquire_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help webcam_acquire

% Last Modified by GUIDE v2.5 12-Dec-2015 21:04:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @webcam_acquire_OpeningFcn, ...
                   'gui_OutputFcn',  @webcam_acquire_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before webcam_acquire is made visible.
function webcam_acquire_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to webcam_acquire (see VARARGIN)

% Choose default command line output for webcam_acquire
handles.output = hObject;
global mycam;
mycam = webcam(1);
handles.cam.Resolution = '320x240';


% display image
axes(handles.cam_axes);
%handles.cam_image = snapshot(mycam);
%image(handles.cam_image);
handles.cam_image = image(snapshot(mycam),'parent',handles.cam_axes);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%image(handles.cam_image,'parent',handles.cam_axes);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
set(handles.cam_axes,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.cam_axes,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');
axis manual off;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes webcam_acquire wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = webcam_acquire_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
handles.output = hObject;
varargout{1} = handles.output;


% --- Executes on button press in Start_Camera.
function Start_Camera_Callback(hObject, eventdata, handles)
% hObject    handle to Start_Camera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mycam
if get(handles.Start_Camera,'value')
%     handles.cam_timer = timer('StartDelay',1,'Period',0.1,'ExecutionMode', 'fixedSpacing');
%     handles.cam_timer.TimerFcn={@(src,evt) get_image(handles,hObject)};
%     guidata(hObject,handles);
%     start(handles.cam_timer);
%     guidata(hObject,handles);
    preview(mycam,handles.cam_image);
else
%    stop(handles.cam_timer);
%    handles.mycam = [];
%    %clear('mycam');
%    fclose('all');
    closePreview(mycam);   
end

% Hint: get(hObject,'Value') returns toggle state of Start_Camera


% % --- Executes during object deletion, before destroying properties.
% function figure1_DeleteFcn(hObject, eventdata, handles)
% % hObject    handle to figure1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% foo = 3;

% --- Executes on button press in close_gui.
function close_gui_Callback(hObject, eventdata, handles)
% hObject    handle to close_gui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mycam
clear -global mycam
delete(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global mycam
clear -global mycam
delete(handles.figure1);
delete(hObject);
