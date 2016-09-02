function varargout = OdorLocator(varargin)

% ODORLOCATOR MATLAB code for OdorLocator.fig (GUI)
%      ODORLOCATOR, by itself, creates a new ODORLOCATOR or raises the existing
%      singleton*.
%
%      H = ODORLOCATOR returns the handle to a new ODORLOCATOR or the handle to
%      the existing singleton*.
%zeros
%      ODORLOCATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ODORLOCATOR.M with the given input arguments.
%
%      ODORLOCATOR('Property','Value',...) creates a new ODORLOCATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OdorLocator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OdorLocator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OdorLocator

% Last Modified by GUIDE v2.5 04-Mar-2016 21:43:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OdorLocator_OpeningFcn, ...
                   'gui_OutputFcn',  @OdorLocator_OutputFcn, ...
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


% --- Executes just before OdorLocator is made visible.
function OdorLocator_OpeningFcn(hObject, eventdata, handles, varargin)
% basic housekeeping
handles.output = hObject;
handles.mfilename = mfilename;

% rig specific settings
handles.computername = textread('hostname.txt','%s'); %#ok<*DTXTRD>
if strcmp(handles.computername,'PRIYANKA-PC')
    handles.file_names.Data(2) = {'C:\Data\Behavior'};
    handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\Behavior'};
    handles.NIchannels = 9;
    handles.DAC_settings.Data = [2.5 1]';
end

% defaults
handles.target_level_array.Data = [1 2 3]';
handles.DAQrates.Data = [500 20]';
handles.which_perturbation.Value = 1;

% clear indicators
handles.RewardStatus.Data = [0 0 0]';
handles.current_trial_block.Data = [1 1 0]';

% set up NI acquisition and reset Arduino
handles.sampling_rate_array = handles.DAQrates.Data;
[handles.NI,handles.Arduino] = configure_NI_and_Arduino_2(handles);

% initiate plots
axes(handles.axes1); % main plot
handles.trial_on = fill(NaN,NaN,[.8 .8 .8]);
hold on;
handles.trial_on.EdgeColor = 'none';
handles.lever_DAC_plot = plot(NaN, NaN,'k','linewidth',1); %lever rescaled
handles.lever_raw_plot = plot(NaN, NaN, 'color',Plot_Colors('b')); %lever raw
handles.stimulus_plot = plot(NaN, NaN, 'color',Plot_Colors('r')); % target odor location
handles.distractor_plot = plot(NaN, NaN, 'color',Plot_Colors('t')); % distractor location
handles.in_target_zone_plot = fill(NaN,NaN,Plot_Colors('r'));
handles.in_target_zone_plot.EdgeColor = 'none';
handles.in_reward_zone_plot = fill(NaN,NaN,Plot_Colors('o'));
handles.in_reward_zone_plot.EdgeColor = 'none';
handles.reward_plot = plot(NaN, NaN,'o','MarkerFaceColor',Plot_Colors('t'),'MarkerSize',10,'MarkerEdgeColor','none'); %rewards
handles.lick_plot = plot(NaN, NaN, 'color',Plot_Colors('o'),'Linewidth',1); %licks
handles.fake_target_plot = plot(NaN, NaN, 'color',[.7 .7 .7]);
handles.targetzone = fill(NaN,NaN,[1 1 0],'FaceAlpha',0.2);
handles.targetzone.EdgeColor = 'none';
handles.minlim = plot(NaN, NaN, 'k','LineStyle',':'); % mark target zone
set(handles.axes1,'YLim',handles.Plot_YLim.Data);

axes(handles.axes4); % markers etc plot
handles.lims_plot = plot([1 1 1],[1 2 3],'r<','MarkerFaceColor','k','MarkerEdgeColor','k');
hold on;
handles.fake_lims_plot = plot([1.5 1.5 1.5],[0 0 0],'r<','MarkerFaceColor','none','MarkerEdgeColor','k');
axis off tight
set(handles.axes4,'YLim',handles.Plot_YLim.Data);

% for webcam
handles.camera_available = 0;
global mycam;
% if ~isempty(webcamlist)
%     
%     mycam = webcam(1);
%     mycam.Resolution = '320x240';
%     handles.camera_available = 1;
% end
% display webcam image, if available
axes(handles.cameraAxes);
if handles.camera_available
    handles.cam_image = image(snapshot(mycam),'parent',handles.cameraAxes);
end
set(handles.cameraAxes,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.cameraAxes,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');

% for data logging
handles.was_last_file_saved = 1;
handles.file_names.Data(1) = {varargin{1}}; %#ok<CCAT1>
handles.traces = zeros(5,5);
handles.timestamps = ones(5,1)*-1;
handles.samplenum = 1;
handles.update_call = 0;

% Update handles structure
guidata(hObject, handles);
calibrate_DAC_Callback(hObject,eventdata,handles);
ZoneLimitSettings_CellEditCallback(hObject,eventdata,handles); % auto calls Update_Arduino

% --- Outputs from this function are returned to the command line.
function varargout = OdorLocator_OutputFcn(hObject, eventdata, handles)  %#ok<*INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in startAcquisition.
function startAcquisition_Callback(hObject, eventdata, handles)
global TotalData;
global TotalTime;
global samplenum;   

if get(handles.startAcquisition,'value')
    set(handles.startAcquisition,'String','Running');
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    
    % clear indicators
    handles.RewardStatus.Data = [0 0 0]';
    handles.current_trial_block.Data = [1 1 0]';
    handles.update_call = 1;
    handles.timestamp.Data = 0;
    
    % clear plots
    handles.trial_on.Vertices = [];
    handles.trial_on.Faces = [];
    handles.in_target_zone_plot.Vertices = [];
    handles.in_target_zone_plot.Faces = [];
    handles.in_reward_zone_plot.Vertices = [];
    handles.in_reward_zone_plot.Faces = [];
    
    set(handles.reward_plot,'XData',NaN,'YData',NaN);
    set(handles.stimulus_plot,'XData',NaN,'YData',NaN);
    set(handles.distractor_plot,'XData',NaN,'YData',NaN);
    set(handles.lick_plot,'XData',NaN,'YData',NaN);
    
    % checks whether last file was saved and enable quiting if not
    if (handles.was_last_file_saved == 0)
        usrans = menu('warning -- last file did not save','quit','continue');
    end
    
    if (handles.was_last_file_saved == 1)||(usrans ~= 1)
        handles.was_last_file_saved = 0;
        if ~exist('C:\temp_data_files\','dir')
            mkdir('C:\temp_data_files\');
        end
        fid1 = fopen('C:\temp_data_files\log.bin','w');
        fid2 = fopen('C:\temp_data_files\settings_log.bin','w');
        
        % main settings - only change in the beginning of each session
        [settings.legends_main, settings.params_main] = Current_Settings(handles,0);
        [settings.legends_trial, params] = Current_Settings(handles,1);
        save('C:\temp_data_files\session_settings.mat','settings*');
        
        % dynamic settings - change within a session
        handles.settingsfileID = fid2;
        fwrite(fid2,params,'double');
        
        handles.hObject = hObject;
        handles.traces = zeros(6000,handles.NIchannels); %???500*60*60*4
        handles.timestamps = -ones(6000,1);
        handles.samplenum = 1;
        handles.write = 1;
        TotalData = handles.traces;
        TotalTime = handles.timestamps;
        samplenum = handles.samplenum;
        
        % enable the motors
        fwrite(handles.Arduino, char(71));
        set(handles.motor_ON,'String','motors ON')
        set(handles.motor_ON,'BackgroundColor',[0.5 0.94 0.94]);
        
        guidata(hObject,handles);
        if isfield(handles,'lis')
            handles.lis.delete
        end
        handles.lis = handles.NI.addlistener('DataAvailable', @(src,evt) NI_Callback(src,evt,handles,hObject,fid1));
        handles.NI.startBackground();
        wait(handles.NI);
        guidata(hObject,handles);
    end
else
   handles.NI.stop;
   release(handles.NI);
   fclose('all');
   set(handles.startAcquisition,'String','Acquire');
   set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
   % disable the motors
   fwrite(handles.Arduino, char(72));
   set(handles.motor_ON,'String','motors OFF')
   set(handles.motor_ON,'BackgroundColor',[0.94 0.94 0.94]);
end

handles.traces = TotalData;
handles.timestamps = TotalTime;
handles.samplenum = samplenum;
guidata(hObject,handles);

% --- Executes when entered data in editable cell(s) in Plot_YLim.
function Plot_YLim_CellEditCallback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to Plot_YLim (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
set(handles.axes1,'YLim',hObject.Data);

% Hints: get(hObject,'String') returns contents of Ylim as text
%        str2double(get(hObject,'String')) returns contents of Ylim as a double

% --- Executes on button press in SaveFile.
function SaveFile_Callback(hObject, eventdata, handles)
% hObject    handle to SaveFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.was_last_file_saved == 1
    usrans = menu(['session ' handles.file_final_name ...
        ' is already saved.'  char(10) 'Do you want to save an additional copy'],...
        'resave','cancel');
else
    usrans = 1;
end

if usrans == 1
    handles.was_last_file_saved = 1;
    
    % read session data
    f = fopen('C:\temp_data_files\log.bin');
    % reads up to six hours -- include the time vec and the data
    a = fread(f,[handles.NIchannels+1 10800000],'double');
    fclose(f);
    
    % read settings log
    f = fopen('C:\temp_data_files\settings_log.bin');
    [~,params] = Current_Settings(handles,1);
    b = fread(f,[length(params) 10800000],'double');
    fclose(f);
    
    % filename for writing data
    animal_name = char(handles.file_names.Data(1));
    foldername_local = char(handles.file_names.Data(2));
    foldername_server = char(handles.file_names.Data(3));
    
    FileExistChecker = 1;
    run_num = 0;
    
    while FileExistChecker
        filename = [foldername_local, filesep, animal_name, filesep, ...
            animal_name, '_', datestr(now, 'yyyymmdd'), ['_r' num2str(run_num) ], '.mat'];
        run_num = run_num + 1;
        if ~exist(fileparts(filename)) %#ok<*EXIST>
            mkdir(fileparts(filename));
        end
        FileExistChecker = exist(filename,'file');
    end
    
    [~,file_final_name]=fileparts(filename);
    handles.file_final_name=file_final_name;
    server_file_name=[foldername_server,filesep,animal_name,filesep,file_final_name];
    if ~exist(fileparts(server_file_name))
        mkdir(fileparts(server_file_name));
    end
    % read session settings
    load('C:\temp_data_files\session_settings.mat'); % loads variable settings
    session_data = settings;
    session_data.timestamps = a(1,:)';
    session_data.trace = a(2:handles.NIchannels+1,:)';
    session_data.trace_legend = Connections_list();
    session_data.params = b';
    
    save(filename,'session_data*');
    save(server_file_name,'session_data*');
    clear a b session_data
    display(['saved to ' filename])
    display(['saved to ' server_file_name])
    guidata(hObject, handles);
end

% --- Executes when entered data in editable cell(s) in TrialSettings.
function TrialSettings_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to TrialSettings (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
Update_Arduino(handles);

% --- Executes on button press in open_valve.
function open_valve_Callback(hObject, eventdata, handles)
% hObject    handle to open_valve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fwrite(handles.Arduino, char(80 + abs(handles.open_valve.Value - 1)));

% --- Executes on button press in reward_now.
function reward_now_Callback(hObject, eventdata, handles)
% hObject    handle to reward_now (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fwrite(handles.Arduino, char(82));

% --- Executes on button press in water_calibrate.
function water_calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to water_calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fwrite(handles.Arduino, char(83));

% --- Executes when entered data in editable cell(s) in RewardControls.
function RewardControls_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to RewardControls (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
Update_Arduino(handles);


% --- Executes when entered data in editable cell(s) in ZoneLimitSettings.
function ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to ZoneLimitSettings (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% compute new target definition
handles.TargetDefinition.Data(1) = handles.TargetDefinition.Data(2) +...
    handles.ZoneLimitSettings.Data(1)+...
    handles.TargetDefinition.Data(2)*handles.ZoneLimitSettings.Data(2);
handles.TargetDefinition.Data(3) = handles.TargetDefinition.Data(2) -...
    handles.ZoneLimitSettings.Data(1)-...
    handles.TargetDefinition.Data(2)*handles.ZoneLimitSettings.Data(2);
handles.PertubationSettings.Data(3) = handles.PertubationSettings.Data(4) +...
    handles.ZoneLimitSettings.Data(1)+...
    handles.PertubationSettings.Data(4)*handles.ZoneLimitSettings.Data(2);
handles.PertubationSettings.Data(5) = handles.PertubationSettings.Data(4) -...
    handles.ZoneLimitSettings.Data(1)-...
    handles.PertubationSettings.Data(4)*handles.ZoneLimitSettings.Data(2);
Update_Arduino(handles);


% --- Executes on button press in min_width_up.
function min_width_up_Callback(hObject, eventdata, handles)
% hObject    handle to min_width_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ZoneLimitSettings.Data(1) = handles.ZoneLimitSettings.Data(1) + 0.05;
ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles);


% --- Executes on button press in min_width_down.
function min_width_down_Callback(hObject, eventdata, handles)
% hObject    handle to min_width_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ((handles.ZoneLimitSettings.Data(1) - 0.05) >= 0)
    handles.ZoneLimitSettings.Data(1) = handles.ZoneLimitSettings.Data(1) - 0.05;
else
    handles.ZoneLimitSettings.Data(1) = 0;
end
ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles);

% --- Executes when entered data in editable cell(s) in DAC_settings.
function DAC_settings_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to DAC_settings (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
Update_Arduino(handles);

% --- Executes on button press in calibrate_DAC.
function calibrate_DAC_Callback(hObject, eventdata, handles)
% hObject    handle to calibrate_DAC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
temp_duration = handles.NI.DurationInSeconds;
handles.NI.DurationInSeconds = 0.5;
if isfield(handles,'lis')
    delete(handles.lis);
end
fwrite(handles.Arduino, char(90));
guidata(hObject, handles);
data = startForeground(handles.NI);
handles.DAC_levels.Data = round([min(data(:,1)) max(data(:,1))]',4,'significant');
handles.NI.DurationInSeconds = temp_duration;

% --- Executes on button press in lever_raw_on.
function lever_raw_on_Callback(hObject, eventdata, handles)
% hObject    handle to lever_raw_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.lever_raw_plot,'LineStyle','none');
else
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.lever_raw_plot,'LineStyle','-');
end
guidata(hObject, handles);

function is_stimulus_on_Callback(hObject, eventdata, handles)
% hObject    handle to is_stimulus_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Update_Arduino(handles);

% --- Executes on button press in is_distractor_on.
function is_distractor_on_Callback(hObject, eventdata, handles)
% hObject    handle to is_distractor_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delay_distractor_by_Callback(hObject, eventdata, handles);

% --- Executes when entered data in editable cell(s) in delay_distractor_by.
function delay_distractor_by_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to delay_distractor_by (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
Update_Arduino(handles);

% --- Executes on button press in stimulus_map.
function stimulus_map_Callback(hObject, eventdata, handles)
% hObject    handle to stimulus_map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Update_Arduino(handles);


% --- Executes on selection change in which_stage.
function which_stage_Callback(hObject, eventdata, handles)
% hObject    handle to which_stage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'Value')
    case 0
        % first stage - very wide target zone, only target, no distractor
    case 1
        % second stage - narrow target zone, only target
    case 2
        
    case 3
end
update_Arduino(handles);

% --- Executes during object creation, after setting all properties.
function which_stage_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to which_stage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in which_perturbation.
function which_perturbation_Callback(hObject, eventdata, handles)
% hObject    handle to which_perturbation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns which_perturbation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from which_perturbation


% --- Executes during object creation, after setting all properties.
function which_perturbation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to which_perturbation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in transfer_functions.
function transfer_functions_Callback(hObject, eventdata, handles)
% hObject    handle to transfer_functions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns transfer_functions contents as cell array
%        contents{get(hObject,'Value')} returns selected item from transfer_functions


% --- Executes during object creation, after setting all properties.
function transfer_functions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transfer_functions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in motor_ON.
function motor_ON_Callback(hObject, eventdata, handles)
% hObject    handle to motor_ON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    fwrite(handles.Arduino, char(71));
    set(hObject,'String','motors ON')
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
else
    fwrite(handles.Arduino, char(72));
    set(hObject,'String','motors OFF')
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in center_motor.
function center_motor_Callback(hObject, eventdata, handles)
% hObject    handle to center_motor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    fwrite(handles.Arduino, char(21));
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
else
    fwrite(handles.Arduino, char(20));
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in motor_home.
function motor_home_Callback(hObject, eventdata, handles)
% hObject    handle to motor_home (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% fwrite(handles.Arduino, char(75));
if get(hObject,'Value')
    fwrite(handles.Arduino, char(22));
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
else
    fwrite(handles.Arduino, char(20));
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
end


% --- Executes on button press in startStopCamera.
function startStopCamera_Callback(hObject, eventdata, handles)
% hObject    handle to startStopCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mycam
if get(hObject,'Value')
    set(hObject,'String','Cam ON');
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    preview(mycam,handles.cam_image);
else
    set(hObject,'String','Cam OFF');
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    closePreview(mycam);
end

% Hint: get(hObject,'Value') returns toggle state of startStopCamera

% --- Executes on button press in grab_camera.
function grab_camera_Callback(hObject, eventdata, handles)
% hObject    handle to grab_camera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mycam
if get(hObject,'Value') && handles.startStopCamera.Value
    closePreview(mycam);
    set(handles.startStopCamera,'String','Cam OFF');
    set(handles.startStopCamera,'BackgroundColor',[0.94 0.94 0.94]);
end
% Hint: get(hObject,'Value') returns toggle state of grab_camera

% --- Executes on button press in close_gui.
function close_gui_Callback(hObject, eventdata, handles)
% hObject    handle to close_gui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mycam %#ok<*NUSED>
clear -global mycam
fclose(instrfind);
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
