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

% Last Modified by GUIDE v2.5 11-Dec-2016 22:03:19

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
    handles.DAC_settings.Data = [1 0]';
    % motor location settings
    handles.motor_params = 4;
    handles.TrialSettings.Data(2) = 0.5;
    % disable transfer function calibrator
    handles.calibrate_transfer_function.Enable = 'off';
    % MFC settings
    handles.MFC_table.Data = [0 2.5 0.5 0.5]';
    % training stage 
    handles.which_stage.Value = 2;
end

% defaults
handles.target_level_array.Data = [1 2.5 3]';
handles.DAQrates.Data = [500 20]';
handles.which_perturbation.Value = 1;

% clear indicators
handles.RewardStatus.Data = [0 0 0]';
handles.current_trial_block.Data = [1 1 0]';

% set up NI acquisition and reset Arduino
handles.sampling_rate_array = handles.DAQrates.Data;
[handles.NI,handles.Arduino,handles.MFC] = configure_NI_and_Arduino_ArCOM(handles);

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

% axes(handles.axes4); % markers etc plot
% handles.lims_plot = plot([1 1 1],[1 2 3],'r<','MarkerFaceColor','k','MarkerEdgeColor','k');
% hold on;
% handles.fake_lims_plot = plot([1 1 1],[0 0 0],'r<','MarkerFaceColor','none','MarkerEdgeColor','k');
% axis off tight
% set(handles.axes4,'YLim',handles.Plot_YLim.Data);

axes(handles.axes9); % Transfer function plot
%handles.TF_left_plot = plot(NaN, NaN,'k','linewidth',2);
%hold on;
%handles.TF_right_plot = plot(NaN, NaN,'r','linewidth',2);
handles.TF_plot = imagesc(abs((-50:1:50)')/50,[0 1]);
colormap('hot');
axis off tight
%set(handles.axes9,'YLim',handles.Plot_YLim.Data);
set(handles.axes9,'YLim',[0 100]);

% for webcam
handles.camera_available = 0;
;
if ~isempty(webcamlist)
    
    handles.mycam = webcam(1);
    % mycam.Resolution = '320x240';
    handles.mycam.Resolution = handles.mycam.AvailableResolutions{1};
    handles.camera_available = 1;
    handles.focus_mode.Value = 1;
    handles.mycam.FocusMode = 'auto';
    handles.focus_value.Data = handles.mycam.Focus;
    handles.mycam.Zoom = 100;
end
% display webcam image, if available
axes(handles.cameraAxes);
if handles.camera_available
    handles.cam_image = image(snapshot(handles.mycam),'parent',handles.cameraAxes);
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
ZoneLimitSettings_CellEditCallback(hObject,eventdata,handles); % auto calls Update_Params
outputSingleScan(handles.MFC,handles.MFC_table.Data');
%Update_Motor_Params(handles);

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
    handles.lastrewardtime = 0;
    
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
        fid3 = fopen('C:\temp_data_files\transferfunction_log.bin','w');
        
        % main settings - only change in the beginning of each session
        [settings.legends_main, settings.params_main] = Current_Settings(handles,0);
        [settings.legends_trial, params] = Current_Settings(handles,1);
        save('C:\temp_data_files\session_settings.mat','settings*');
        
        % dynamic settings - change within a session
        handles.settingsfileID = fid2;
        fwrite(fid2,[settings.params_main params],'double');
        handles.TransferFunctionfileID = fid3;
        
        handles.hObject = hObject;
        handles.traces = zeros(6000,handles.NIchannels); %???500*60*60*4
        handles.timestamps = -ones(6000,1);
        handles.samplenum = 1;
        handles.write = 1;
        TotalData = handles.traces;
        TotalTime = handles.timestamps;
        samplenum = handles.samplenum;
        
        % enable the motors
        handles.Arduino.write(71, 'uint16'); % fwrite(handles.Arduino, char(71));
        handles.Arduino.write(60, 'uint16'); %fwrite(handles.Arduino, char(60));
        
        set(handles.motor_status,'String','ON')
        set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
        handles.motor_home.Enable = 'on';
        
        if handles.which_stage.Value>1
            % start the Arduino timer
            handles.Arduino.write(11, 'uint16'); %fwrite(handles.Arduino, char(11));
            tic
            while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
            end
            if(handles.Arduino.Port.BytesAvailable == 0)
                error('arduino: Motor Timer Start did not send confirmation byte')
            elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==6
                disp('arduino: Motor Timer Started');
            end
        end
        
        % enable transfer function calibrator
        handles.calibrate_transfer_function.Enable = 'on';
    
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
   handles.Arduino.write(70, 'uint16'); %fwrite(handles.Arduino, char(70));
   set(handles.motor_status,'String','OFF')
   set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
   handles.motor_home.Enable = 'off';
   % stop the Arduino timer
   handles.Arduino.write(12, 'uint16'); %fwrite(handles.Arduino, char(12));
   tic
   while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
   end
   if(handles.Arduino.Port.BytesAvailable == 0)
       error('arduino: Motor Timer Stop did not send confirmation byte')
   elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==7
       disp('arduino: Motor Timer Stopped');
   end
   
   % stop TF calibration if running
   if handles. calibrate_transfer_function.Value
       handles. calibrate_transfer_function.Value = 0;
        calibrate_transfer_function_Callback(hObject, eventdata, handles);
   end
   
   % disable transfer function calibrator
    handles.calibrate_transfer_function.Enable = 'off';
end

handles.traces = TotalData;
handles.timestamps = TotalTime;
handles.samplenum = samplenum;
guidata(hObject,handles);

% --- Executes when entered data in editable cell(s) in Plot_YLim.
function Plot_YLim_CellEditCallback(hObject, eventdata, handles) %#ok<*DEFNU>
set(handles.axes1,'YLim',hObject.Data);

% --- Executes on button press in SaveFile.
function SaveFile_Callback(hObject, eventdata, handles)
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
    [~,params1] = Current_Settings(handles,0);
    [~,params2] = Current_Settings(handles,1);
    b = fread(f,[length(params1)+length(params2) 10800000],'double');
    fclose(f);
    
    % read TF log
    f = fopen('C:\temp_data_files\transferfunction_log.bin');
    %[~,params] = Current_Settings(handles,1);
    c = fread(f,[(2+handles.TransferFunction.Data(1)) 10800000],'double');
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
    session_data.TF = c';
    
    save(filename,'session_data*');
    save(server_file_name,'session_data*');
    clear a b session_data
    display(['saved to ' filename])
    display(['saved to ' server_file_name])
    guidata(hObject, handles);
end

% --- Executes when entered data in editable cell(s) in TrialSettings.
function TrialSettings_CellEditCallback(hObject, eventdata, handles)
Update_Params(handles);

% --- Executes on button press in open_valve.
function open_valve_Callback(hObject, eventdata, handles)
handles.Arduino.write(80 + handles.open_valve.Value, 'uint16'); %fwrite(handles.Arduino, char(80 + handles.open_valve.Value));

% --- Executes on button press in reward_now.
function reward_now_Callback(hObject, eventdata, handles)
if handles.which_stage.Value==1
    if ((handles.timestamp.Data - handles.lastrewardtime) > 20)
        handles.lastrewardtime = handles.timestamp.Data; % update 'last reward'
        handles.Arduino.write(82, 'uint16'); %fwrite(handles.Arduino, char(82));
        handles.RewardStatus.Data(3) = handles.RewardStatus.Data(3) + 1;
    end
else
    handles.lastrewardtime = handles.timestamp.Data; % update 'last reward'
    handles.Arduino.write(82, 'uint16'); %fwrite(handles.Arduino, char(82));
    handles.RewardStatus.Data(3) = handles.RewardStatus.Data(3) + 1;
end

handles.lastrewardtime = handles.timestamp.Data;
guidata(hObject, handles);

% --- Executes on button press in water_calibrate.
function water_calibrate_Callback(hObject, eventdata, handles)
handles.Arduino.write(83, 'uint16'); %fwrite(handles.Arduino, char(83));

% --- Executes when entered data in editable cell(s) in RewardControls.
function RewardControls_CellEditCallback(hObject, eventdata, handles)
Update_Params(handles);


% --- Executes when entered data in editable cell(s) in ZoneLimitSettings.
function ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles)
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

Update_Params(handles);
Update_TransferFunction_discrete(handles);
% --------------------------------------------------------------------

function update_current_target_level_Callback(hObject, eventdata, handles)
foo = get(hObject,'tag');
handles.TargetDefinition.Data(2) = handles.target_level_array.Data(str2num(foo(end)));
ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles);


% --- Executes on button press in min_width_up.
function min_width_up_Callback(hObject, eventdata, handles)
handles.ZoneLimitSettings.Data(1) = handles.ZoneLimitSettings.Data(1) + 0.05;
ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles);


% --- Executes on button press in min_width_down.
function min_width_down_Callback(hObject, eventdata, handles)
if ((handles.ZoneLimitSettings.Data(1) - 0.05) >= 0)
    handles.ZoneLimitSettings.Data(1) = handles.ZoneLimitSettings.Data(1) - 0.05;
else
    handles.ZoneLimitSettings.Data(1) = 0;
end
ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles);

% --- Executes on button press in update_zones.
function update_zones_Callback(hObject, eventdata, handles)
% safety - turn motor off
handles.Arduino.write(70, 'uint16'); %fwrite(handles.Arduino, char(70));
set(handles.motor_status,'String','OFF')
set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
handles.motor_home.Enable = 'off';

% update transfer function
Update_Params(handles);
Update_TransferFunction_discrete(handles);
handles.locations_per_zone.ForegroundColor = 'k';
% Hint: get(hObject,'Value') returns toggle state of update_zones

% turn motor on
handles.Arduino.write(71, 'uint16'); %fwrite(handles.Arduino, char(71));
set(handles.motor_status,'String','ON')
set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
handles.motor_home.Enable = 'on';

function change_in_zones_Callback(hObject, eventdata, handles)
hObject.ForegroundColor = 'r';

% --- Executes when entered data in editable cell(s) in DAC_settings.
function DAC_settings_CellEditCallback(hObject, eventdata, handles)
% safety - turn motor off
handles.Arduino.write(70, 'uint16'); %fwrite(handles.Arduino, char(70));
set(handles.motor_status,'String','OFF')
set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
handles.motor_home.Enable = 'off';
    
Update_Params(handles);
Update_TransferFunction_discrete(handles);

% turn motor on
handles.Arduino.write(71, 'uint16'); %fwrite(handles.Arduino, char(71));
set(handles.motor_status,'String','ON')
set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
handles.motor_home.Enable = 'on';    

% --- Executes on button press in calibrate_DAC.
function calibrate_DAC_Callback(hObject, eventdata, handles)
temp_duration = handles.NI.DurationInSeconds;
handles.NI.DurationInSeconds = 0.5;
if isfield(handles,'lis')
    delete(handles.lis);
end
handles.Arduino.write(90, 'uint16'); %fwrite(handles.Arduino, char(90));
guidata(hObject, handles);
data = startForeground(handles.NI);
handles.DAC_levels.Data = round([min(data(:,1)) max(data(:,1))]',4,'significant');
handles.NI.DurationInSeconds = temp_duration;

% --- Executes on button press in lever_raw_on.
function lever_raw_on_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.lever_raw_plot,'LineStyle','none');
else
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.lever_raw_plot,'LineStyle','-');
end
guidata(hObject, handles);

function is_stimulus_on_Callback(hObject, eventdata, handles)
Update_Params(handles);

% --- Executes on button press in is_distractor_on.
function is_distractor_on_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
    set(handles.distractor_plot,'LineStyle','-');
else
    set(handles.distractor_plot,'LineStyle','none');
end
delay_distractor_by_CellEditCallback(hObject, eventdata, handles);

% --- Executes when entered data in editable cell(s) in delay_distractor_by.
function delay_distractor_by_CellEditCallback(hObject, eventdata, handles)
Update_Params(handles);

% --- Executes on button press in stimulus_map.
function stimulus_map_Callback(hObject, eventdata, handles)
Update_Params(handles);


% --- Executes on selection change in which_stage.
function which_stage_Callback(hObject, eventdata, handles)
switch get(hObject,'Value')
    case 0
        % first stage - very wide target zone, only target, no distractor
    case 1
        % second stage - narrow target zone, only target
    case 2
        
    case 3
end
Update_Params(handles);

% --- Executes during object creation, after setting all properties.
function which_stage_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
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
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in motor_toggle.
function motor_toggle_Callback(hObject, eventdata, handles)
if isequal(handles.motor_status.String,'ON')
    handles.Arduino.write(70, 'uint16'); %fwrite(handles.Arduino, char(70));
    set(handles.motor_status,'String','OFF')
    set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
    handles.motor_home.Enable = 'off';
else    
    handles.Arduino.write(71, 'uint16'); %fwrite(handles.Arduino, char(71));
    set(handles.motor_status,'String','ON')
    set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
    handles.motor_home.Enable = 'on';
end

% % --- Executes on button press in motor_center.
% function motor_center_Callback(hObject, eventdata, handles)
% pause(0.01);
% if get(hObject,'Value')
%     handles.Arduino.write(61, 'uint16'); %fwrite(handles.Arduino, char(61));
%     set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
%     set(handles.motor_status,'String','ON')
%     set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
% else
%     handles.Arduino.write(60, 'uint16'); %fwrite(handles.Arduino, char(60));
%     set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
% end

% --- Executes on button press in motor_home.
function motor_home_Callback(hObject, eventdata, handles)
pause(0.01);
if get(hObject,'Value')
    handles.Arduino.write(61, 'uint16'); % handler - move motor to specific location
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.motor_status,'String','ON')
    set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
    %my_location = handles.all_locations.Value
    %handles.Arduino.write(61, 'uint16'); % which location    
else
    handles.Arduino.write(60, 'uint16'); %fwrite(handles.Arduino, char(60));
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in change_motor_params.
function change_motor_params_Callback(hObject, eventdata, handles)
prompt = {'Enter stepsize (1-6):'};
dlg_title = 'Motor movement settings';
num_lines = 1;
defaultans = {num2str(handles.motor_params)};
userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
if ~isempty(userans)
    handles.motor_params = str2num(char(userans(2)))+1;
    guidata(hObject, handles);
    stepsize = handles.motor_params + 70;
    handles.Arduino.write(stepsize, 'uint16'); %fwrite(h.Arduino, char(stepsize));
    %Update_Motor_Params(handles);
end

% --- Executes on button press in calibrate_transfer_function.
function calibrate_transfer_function_Callback(hObject, eventdata, handles)
if get(hObject,'Value') 
    prompt = {'Enter time at each location (ms):', 'Randomize locations (1 = yes/ 0 = no):'};
    dlg_title = 'Transfer function relay settings';
    num_lines = 1;
    if ~isfield(handles,'location_update_params')
        defaultans = {'1000','0'};
    else
        defaultans = {num2str(handles.location_update_params(1)),num2str(handles.location_update_params(2))};
    end
    userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
    if ~isempty(userans)
        handles.location_update_params = [str2num(char(userans(1))) str2num(char(userans(2)))];
        guidata(hObject, handles);
        Update_LocationSequence(handles);
    end
else
    
    Update_Params(handles);
    Update_TransferFunction_discrete(handles);
end

% --- Executes when entered data in editable cell(s) in MFC_table.
function MFC_table_CellEditCallback(hObject, eventdata, handles)
outputSingleScan(handles.MFC,handles.MFC_table.Data');

% --- Executes on button press in Zero_MFC.
function Zero_MFC_Callback(hObject, eventdata, handles)
% hObject    handle to Zero_MFC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.MFC_table.Data = 0*handles.MFC_table.Data;
outputSingleScan(handles.MFC,handles.MFC_table.Data');
% Hint: get(hObject,'Value') returns toggle state of Zero_MFC

% --- Executes on button press in valve_odor_A.
function valve_odor_A_Callback(hObject, eventdata, handles)
% hObject    handle to valve_odor_A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Arduino.write(44 + handles.valve_odor_A.Value, 'uint16'); %fwrite(handles.Arduino, char(44 + handles.valve_odor_A.Value));
if handles.valve_odor_A.Value
    set(handles.valve_odor_A,'String','ON')
    set(handles.valve_odor_A,'BackgroundColor',[0.5 0.94 0.94]);
else
    set(handles.valve_odor_A,'String','OFF')
    set(handles.valve_odor_A,'BackgroundColor',[0.94 0.94 0.94]);
end


% --- Executes on button press in valve_odor_B.
function valve_odor_B_Callback(hObject, eventdata, handles)
% hObject    handle to valve_odor_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Arduino.write(46 + handles.valve_odor_A.Value, 'uint16'); %fwrite(handles.Arduino, char(46 + handles.valve_odor_B.Value));
if handles.valve_odor_A.Value
    set(handles.valve_odor_B,'String','ON')
    set(handles.valve_odor_B,'BackgroundColor',[0.5 0.94 0.94]);
else
    set(handles.valve_odor_B,'String','OFF')
    set(handles.valve_odor_B,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in startStopCamera.
function startStopCamera_Callback(hObject, eventdata, handles)
% hObject    handle to startStopCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    set(hObject,'String','Cam ON');
    set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    preview(handles.mycam,handles.cam_image);
else
    set(hObject,'String','Cam OFF');
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    closePreview(handles.mycam);
end

% Hint: get(hObject,'Value') returns toggle state of startStopCamera

% --- Executes on button press in grab_camera.
function grab_camera_Callback(hObject, eventdata, handles)
if get(hObject,'Value') && handles.startStopCamera.Value
    closePreview(handles.mycam);
    set(handles.startStopCamera,'String','Cam OFF');
    set(handles.startStopCamera,'BackgroundColor',[0.94 0.94 0.94]);
end
% Hint: get(hObject,'Value') returns toggle state of grab_camera

% --- Executes on selection change in focus_mode.
function focus_mode_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String')); % returns focus_mode contents as cell array
handles.mycam.FocusMode = contents{get(hObject,'Value')}; %returns selected item from focus_mode
handles.focus_value.Data = handles.mycam.Focus;
if get(hObject,'Value') == 1
    handles.focus_value.Enable = 'off';
else
    handles.focus_value.Enable = 'on';
end

% --- Executes during object creation, after setting all properties.
function focus_mode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on slider movement.
function Adjust_Zoom_Callback(hObject, eventdata, handles)
handles.mycam.Zoom = hObject.Value;

% --- Executes during object creation, after setting all properties.
function Adjust_Zoom_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes when entered data in editable cell(s) in focus_value.
function focus_value_CellEditCallback(hObject, eventdata, handles)
if (hObject.Data>=0) && (hObject.Data<=250)
    %handles.mycam.Focus = hObject.Data;
elseif (hObject.Data<0)
    hObject.Data = 0;
else
    hObject.Data = 250;
end
handles.mycam.Focus = hObject.Data;

% --- Executes on button press in close_gui.
function close_gui_Callback(hObject, eventdata, handles)
% close valves and MFCs
outputSingleScan(handles.MFC,0*handles.MFC_table.Data');
handles.Arduino.write(44, 'uint16');

outputSingleScan(handles.MFC,0*handles.MFC_table.Data');
delete(handles.figure1);
handles.Arduino.write(12, 'uint16'); %fwrite(handles.Arduino, char(11));
tic
while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
end
if(handles.Arduino.Port.BytesAvailable == 0)
    handles.Arduino.close;%fclose(instrfind);
    error('arduino: arduino did not send confirmation byte in time')
end
if handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==7
    handles.Arduino.close;%fclose(instrfind);
    disp('arduino: disconnected, handshake successful');
else
    handles.Arduino.close;%fclose(instrfind);
    disp('arduino: disconnected, handshake unsuccessful');
end
% if exist(handles)
%     delete(handles.figure1);
% end

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)


