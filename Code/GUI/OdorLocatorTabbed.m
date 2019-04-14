function varargout = OdorLocatorTabbed(varargin)

% ODORLOCATORTABBED MATLAB code for OdorLocatorTabbed.fig (GUI)
%      ODORLOCATORTABBED, by itself, creates a new ODORLOCATORTABBED or raises the existing
%      singleton*.
%
%      H = ODORLOCATORTABBED returns the handle to a new ODORLOCATORTABBED or the handle to
%      the existing singleton*.
%zeros
%      ODORLOCATORTABBED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ODORLOCATORTABBED.M with the given input arguments.
%
%      ODORLOCATORTABBED('Property','Value',...) creates a new ODORLOCATORTABBED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OdorLocatorTabbed_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OdorLocatorTabbed_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OdorLocatorTabbed

% Last Modified by GUIDE v2.5 13-Oct-2018 14:29:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OdorLocatorTabbed_OpeningFcn, ...
                   'gui_OutputFcn',  @OdorLocatorTabbed_OutputFcn, ...
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


% --- Executes just before OdorLocatorTabbed is made visible.
function OdorLocatorTabbed_OpeningFcn(hObject, eventdata, handles, varargin)

%% GUI Tabs
%Create tab groupA - motor and odors
handles.tgroupA = uitabgroup('Parent', handles.figure1,'TabLocation', 'top',...
    'Position', [0 0 0.14300 0.4500] );
handles.tabA1 = uitab('Parent', handles.tgroupA, 'Title', 'ClearPathMotor');
handles.tabA2 = uitab('Parent', handles.tgroupA, 'Title', 'Odors');
%Place panels into each tab
set(handles.A1,'Parent',handles.tabA1)
set(handles.A2,'Parent',handles.tabA2)
%Reposition each panel to same location as panel 1
handles.A1.Position = [1.000    0.1   25.6000   24.0000];
set(handles.A2,'position',get(handles.A1,'position'));

%Create tab groupB - Session controls, Extra controls
handles.tgroupB = uitabgroup('Parent', handles.figure1,'TabLocation', 'top',...
    'Position',[0.144 0 0.434 0.4500]);
handles.tabB1 = uitab('Parent', handles.tgroupB, 'Title', 'Session controls');
handles.tabB2 = uitab('Parent', handles.tgroupB, 'Title', 'Extra');
handles.tabB3 = uitab('Parent', handles.tgroupB, 'Title', 'Plots');
%Place panels into each tab
set(handles.B1,'Parent',handles.tabB1)
set(handles.B2,'Parent',handles.tabB2)
set(handles.B3,'Parent',handles.tabB3)
%Reposition each panel to same location as panel 1
handles.B1.Position = [1    0.1   84.6000   24.0000];
set(handles.B2,'position',get(handles.B1,'position'));
set(handles.B3,'position',get(handles.B2,'position'));

%Create tab groupC - Session controls, Extra controls
handles.tgroupC = uitabgroup('Parent', handles.figure1,'TabLocation', 'top',...
    'Position',[0.579 0 0.422 0.4800]);
handles.tabC1 = uitab('Parent', handles.tgroupC, 'Title', 'Session Status');
handles.tabC2 = uitab('Parent', handles.tgroupC, 'Title', 'Session Extras');
%Place panels into each tab
set(handles.C1,'Parent',handles.tabC1)
set(handles.C2,'Parent',handles.tabC2)
%Reposition each panel to same location as panel 1
handles.C1.Position = [1.0000    0.1000   82.0000   25.6154];
set(handles.C2,'position',get(handles.C1,'position'));

%% Load Settings
handles.output = hObject;
handles.mfilename = mfilename;
handles.startAcquisition.Enable = 'off';

% rig specific settings
handles.computername = textread(fullfile(fileparts(mfilename('fullpath')),'hostname.txt'),'%s');
handles.useserver = 1;
[handles] = RigDefaultParams(handles);

% load mouse specific settings
handles.file_names.Data(1) = {varargin{1}}; %#ok<CCAT1>
% create the data directories if they don't already exist
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
foldername_server = char(handles.file_names.Data(3));
if ~exist(fullfile(foldername_local,animal_name),'dir')
    mkdir(fullfile(foldername_local,animal_name));
    disp('making local data directory');
    handles.TargetHold.Data = [5 10 15]';
    handles.TriggerHold.Data = [5 10 15]';
    handles.TrialSettings.Data(end) = 200;
end
if handles.useserver
    if ~exist(fullfile(foldername_server,animal_name),'dir')
    	mkdir(fullfile(foldername_server,animal_name));
        disp('making remote data directory');
    end
end

% mouse specific settings
[handles] = MouseDefaults(handles);
% update targets accordingly
handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
% initialize targetdefinition
handles.TargetDefinition.Data(2) = handles.target_level_array.Data(2);

% load settings
handles = LastSessionSettings(handles);

% get weight data if available
filename = [foldername_local, filesep, animal_name, '_WeightLog.mat'];
if exist(filename) %#ok<*EXIST>
    load(filename);
    w_o = str2num(char(weight(1,3)));
    w_c = str2num(char(weight(end,3)));
    w_p = round(100*w_c/w_o,0,'decimals');
    handles.WeightString.String = [num2str(w_p),'%,  ', num2str(w_c), ' grams,  [85% = ', num2str(0.85*w_o), ' grams]'];
else
    handles.WeightString.String = 'weight data unavailable';
end

%% set up NI acquisition and reset Arduino
handles.sampling_rate_array = handles.DAQrates.Data;
%[handles.NI,handles.Arduino,handles.MFC,handles.Odors,handles.Teensy] = configure_NI_and_Arduino_ArCOM(handles);
[handles.NI,handles.MFC,handles.Channels,handles.NIchannels] = configure_NIDAQ(handles);
handles.Arduino = configure_ArduinoMain(handles);

%% Files - for data logging
handles.was_last_file_saved = 1;
handles.traces = zeros(5,5);
handles.timestamps = ones(5,1)*-1;
handles.samplenum = 1;
handles.targetLevel = zeros(2,2);
handles.update_call = 0;

%% clear indicators
handles.Reward_Report.Data = zeros(size(handles.Reward_Report.Data));
handles.ProgressReport.Data = zeros(size(handles.ProgressReport.Data));
handles.ProgressReportPerturbed.Data = zeros(size(handles.ProgressReportPerturbed.Data));
handles.hold_times.Data = zeros(size(handles.hold_times.Data));
handles.MeanHoldTimes.Data = zeros(size(handles.MeanHoldTimes.Data));
handles.current_trial_block.Data(1:4,1) = [1 1 0 1]';
handles.Date.String = datestr(now, 'mm-dd-yy');
handles.StartTime.Visible = 'off';
handles.StopTime.Visible = 'off';

%% initiate plots
axes(handles.axes1); % main plot
% three different trial plots - one for each odor
handles.trial_on_1 = fill(NaN,NaN,[.8 .8 .8]);
hold on;
handles.trial_on_1.EdgeColor = 'none';
handles.trial_on_2 = fill(NaN,NaN,[0.8941    0.9412    0.9020]);
handles.trial_on_2.EdgeColor = 'none';
handles.trial_on_3 = fill(NaN,NaN,[0.8706    0.9216    0.9804]);
handles.trial_on_3.EdgeColor = 'none';
handles.trial_on_4 = fill(NaN,NaN,[0.93    0.84    0.84]);
handles.trial_on_4.EdgeColor = 'none';

handles.lever_DAC_plot = plot(NaN, NaN,'k','linewidth',1); %lever rescaled
handles.lever_raw_plot = plot(NaN, NaN, 'color',Plot_Colors('b')); %lever raw
handles.stimulus_plot = plot(NaN, NaN, 'color',Plot_Colors('r')); % target odor location (rotary encoder)
handles.in_target_zone_plot = fill(NaN,NaN,Plot_Colors('r'));
handles.in_target_zone_plot.EdgeColor = 'none';
handles.in_reward_zone_plot = fill(NaN,NaN,Plot_Colors('o'));
handles.in_reward_zone_plot.EdgeColor = 'none';
handles.reward_plot = plot(NaN, NaN, 'color',Plot_Colors('t'),'Linewidth',1.25); %rewards
handles.lick_plot = plot(NaN, NaN, 'color',Plot_Colors('r'),'Linewidth',1); %licks
handles.camerasync_plot = plot(NaN, NaN, 'color',Plot_Colors('pl'),'Linewidth',1); %point-grey cam sync
handles.camerasync2_plot = plot(NaN, NaN, 'color',Plot_Colors('pd'),'Linewidth',1); %point-grey cam sync
handles.homesensor_plot = plot(NaN, NaN,'k'); %homesensor
handles.targetzone = fill(NaN,NaN,[1 1 0],'FaceAlpha',0.2);
handles.targetzone.EdgeColor = 'none';
handles.fake_target_plot = plot(NaN, NaN, 'color',[.7 .7 .7]);
handles.minlim = plot(NaN, NaN, 'k','LineStyle',':'); % lower limit of lever range (trigger Off)

% currently unused plots
handles.respiration_plot = plot(NaN, NaN, 'color',Plot_Colors('t')); % respiration sensor 1
handles.lickpiezo_plot = plot(NaN, NaN, 'color',Plot_Colors('p')); % respiration sensor 2

set(handles.axes1,'YLim',handles.Plot_YLim.Data,'YTick',[]);

axes(handles.axes9); % Transfer function plot
handles.TF_plot = imagesc(((-50:1:50)')/50,[-1 1]);
colormap(brewermap([handles.ManifoldOutlets],'rdbu'));
axis off tight
set(handles.axes9,'YLim',[0 100]);

axes(handles.axes4); % motor location plot
handles.motor_location = plot([1],[2],'r<','MarkerFaceColor','k','MarkerEdgeColor','k');
axis off tight
set(handles.axes4,'YLim',[0 100]);
set(handles.axes4, 'Color', 'none');

axes(handles.axes10); % which target plot
handles.thistarget = plot([1],[2],'r>','MarkerFaceColor','k','MarkerEdgeColor','k');
axis off tight
set(handles.axes10,'YLim',[0.5 12.5],'YDir','reverse');
set(handles.axes10, 'Color', 'none');

%% webcam
handles.camera_available = 0;
if ~isempty(webcamlist)
    
    switch char(handles.computername)
       case {'JUSTINE'}
            handles.mycam = webcam(1);% {'logitech'}
            handles.mycam.Resolution = handles.mycam.AvailableResolutions{1};
            handles.camera_available = 1;
            handles.focus_mode.Enable = 'on';
            handles.exposure_mode.Enable = 'on';
            handles.exposure_value.Enable = 'on';
            handles.camera_available = 1;
            handles.focus_mode.Value = 2;
            handles.mycam.ExposureMode = 'auto';
            handles.exposure_mode.Value = 1;                                                                      
            handles.mycam.Focus = 250;
            handles.exposure_value.Data = handles.mycam.Exposure;
            handles.mycam.Zoom = 100;
       case {'PRIYANKA-HP'}
            handles.mycam = webcam(1);% {'USB}2.0 PC CAMERA', 'USB Video Device'}
            handles.mycam.Resolution = handles.mycam.AvailableResolutions{1};
            handles.camera_available = 1;
            handles.focus_mode.Enable = 'off';
            handles.exposure_mode.Enable = 'off';
            handles.exposure_value.Enable = 'off';
        case {'PRIYANKA-PC','DESKTOP-05QAM9D'}
            handles.mycam = webcam(2);% {'USB}2.0 PC CAMERA', 'USB Video Device'}
            handles.mycam.Resolution = handles.mycam.AvailableResolutions{1};
            handles.camera_available = 1;
            handles.focus_mode.Enable = 'off';
            handles.exposure_mode.Enable = 'off';
            handles.exposure_value.Enable = 'off';
    end

end
% display webcam image, if available
axes(handles.cameraAxes);
if handles.camera_available
    handles.cam_image = image(snapshot(handles.mycam),'parent',handles.cameraAxes);
end
set(handles.cameraAxes,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.cameraAxes,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');

%% Others
guidata(hObject, handles); % Update handles structure
lever_raw_on_Callback(hObject,eventdata,handles);
respiration_on_Callback(hObject,eventdata,handles);
lick_piezo_on_Callback(hObject,eventdata,handles);
camera_sync_on_Callback(hObject,eventdata,handles);
calibrate_DAC_Callback(hObject,eventdata,handles);
ZoneLimitSettings_CellEditCallback(hObject,eventdata,handles); % auto calls Send2Arduino

% Zero MFCs
if ~isempty(handles.MFC)
    Zero_MFC_Callback(hObject, eventdata, handles);
end

% set up odors
handles.Odor_list.Value = 1; % only blank vial
handles.odor_vial.Value = 1;
odor_vial_Callback(hObject, eventdata, handles);
handles.odor_to_manifold.Value = 1;
handles.air_to_manifold.Value = 0;
handles.Vial0.Value = 1;
handles.Vial1.Value = 0;
handles.Vial2.Value = 0;
handles.Vial3.Value = 0;
Vial2Manifold_Callback(hObject, eventdata, handles);

% disable motor override
handles.motor_override.Value = 0;
motor_override_Callback(hObject, eventdata, handles);
handles.startAcquisition.Enable = 'on';
warning('off','MATLAB:callback:error');


% --- Outputs from this function are returned to the command line.
function varargout = OdorLocatorTabbed_OutputFcn(hObject, eventdata, handles)  %#ok<*INUSL>
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
global TargetLevel;
global IsRewardedTrial;
global TrialsToPerturb;

if get(handles.startAcquisition,'value')    
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
        
        % get settings and write to file
        [mysettings.legends, mysettings.params] = GetSettings4Arduino(handles);
        save('C:\temp_data_files\session_settings.mat','mysettings*');
        handles.settingsfileID = fid2;
        fwrite(fid2,[handles.timestamp.Data mysettings.params],'double');
        
        handles.TransferFunctionfileID = fid3;
        
        handles.hObject = hObject;
        handles.traces = zeros(6000,handles.NIchannels); %???500*60*60*4
        handles.timestamps = -ones(6000,1);
        handles.samplenum = 1;
        handles.targetlevel = zeros(6000,2);
        handles.write = 1;
        TotalData = handles.traces;
        TotalTime = handles.timestamps;
        samplenum = handles.samplenum;
        TargetLevel = handles.targetlevel;
        IsRewardedTrial = 1;
        % set up perturbation trial order
        if handles.PerturbationSettings.Data(1)
            TrialsToPerturb = zeros(1,ceil(1/handles.PerturbationSettings.Data(1)));
            TrialsToPerturb(1) = 1;
        end
        
        set(handles.startAcquisition,'String','Running');
        set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
        time = regexp(char(datetime('now')),' ','split');
        handles.Date.String = datestr(now, 'mm-dd-yy');
        handles.StartTime.String = char(time(2));
        handles.StartTime.Visible = 'on';
        handles.StopTime.Visible = 'off';
        
        % update target levels
        handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
        handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
        handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);

        % clear indicators and reset flags
        handles.Reward_Report.Data = zeros(size(handles.Reward_Report.Data));
        handles.ProgressReport.Data = zeros(size(handles.ProgressReport.Data));
        handles.ProgressReportPerturbed.Data = zeros(size(handles.ProgressReportPerturbed.Data));
        handles.hold_times.Data = zeros(size(handles.hold_times.Data));
        handles.MeanHoldTimes.Data = zeros(size(handles.MeanHoldTimes.Data));
        handles.current_trial_block.Data(1:4,1) = [1 1 0 1]';
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
        set(handles.respiration_plot,'XData',NaN,'YData',NaN);
        set(handles.lickpiezo_plot,'XData',NaN,'YData',NaN);
        set(handles.lick_plot,'XData',NaN,'YData',NaN);
        
        % turn ON MFCs
        if ~isempty(handles.MFC)
            handles.Zero_MFC.Value = 1;
            handles.Zero_MFC.String = 'MFCs OFF';
            Zero_MFC_Callback(hObject, eventdata, handles);
        end
        
        % open odor vials
        handles.Odor_list.Value = 1 + [0 1 2 3]'; % active odors
        handles.odor_vial.Value = 1;
        odor_vial_Callback(hObject, eventdata, handles);
        handles.odor_to_manifold.Value = 1;
        handles.air_to_manifold.Value = 0;
        handles.Vial0.Value = 1;
        handles.Vial1.Value = 0;
        handles.Vial2.Value = 0;
        handles.Vial3.Value = 0;
        Vial2Manifold_Callback(hObject, eventdata, handles);
        
        % disable/enable controls
        handles.calibrate_transfer_function.Enable = 'on';
        handles.water_calibrate.Enable = 'off';
        handles.open_valve.Enable = 'off';
        handles.CleaningRoutine.Value = 0;
        handles.CleaningRoutine.Enable = 'off';
        handles.TFtype.Enable = 'off';
        
        % update motor stepsize 
        % different for fixgain (stepsize = 2) vs. variable gain (stepsize = 1)
        handles.Arduino.write(73 + handles.TFtype.Value,'uint16');
        %handles.Arduino.write(73);
        
        % Calibrate Rotary encoder
        handles = CalibrateRotaryEncoder(handles);
        % disable motor override
        handles.motor_override.Value = 0;
        motor_override_Callback(hObject, eventdata, handles);
        % enable the motors
        set(handles.motor_status,'String','OFF')
        motor_toggle_Callback(hObject, eventdata, handles);
        
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

        guidata(hObject,handles);
        if isfield(handles,'lis')
            handles.lis.delete
        end
        
        % refresh DAC levels
        calibrate_DAC_Callback(hObject,eventdata,handles);
        
        % update plot height and position to match that of the lever graph
        DAC_limits = handles.DAC_levels.Data;
        scalefactor = handles.axes1.Position(4)/sum(abs(handles.Plot_YLim.Data));
        Y_position = handles.axes1.Position(2) + scalefactor*abs(handles.Plot_YLim.Data(1) - DAC_limits(1));
        Height = scalefactor*abs(DAC_limits(2) - DAC_limits(1));
        handles.axes9.Position(2) = Y_position;
        handles.axes9.Position(4) = Height;
        handles.axes4.Position(2) = Y_position;
        handles.axes4.Position(4) = Height;
        NextTrial_Callback(handles);
        
        % update pointer to match motor location
        handles.axes4.YLim = [0 handles.TransferFunction.Data(1)];
        handles.motor_location.YData = MapRotaryEncoderToTFColorMap(handles, handles.Rotary.Limits(3));
       
        handles.lis = handles.NI.addlistener('DataAvailable', @(src,evt) NIDAQ_Callback(src,evt,handles,hObject,fid1));
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
   time = regexp(char(datetime('now')),' ','split');
   handles.StopTime.String = char(time(2));
   handles.StopTime.Visible = 'on';
    
   % disable the motors
   set(handles.motor_status,'String','ON')
   motor_toggle_Callback(hObject, eventdata, handles);
   
   % turn OFF MFCs
   if ~isempty(handles.MFC)
       handles.Zero_MFC.Value = 0;
       Zero_MFC_Callback(hObject, eventdata, handles);
   end
   
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
   
   % close odor vials
   handles.Odor_list.Value = 1;
   handles.odor_vial.Value = 1;
   odor_vial_Callback(hObject, eventdata, handles);
   handles.odor_to_manifold.Value = 1;
   handles.air_to_manifold.Value = 0;
   handles.Vial0.Value = 1;
   handles.Vial1.Value = 0;
   handles.Vial2.Value = 0;
   handles.Vial3.Value = 0;
   Vial2Manifold_Callback(hObject, [], handles);
   
   % stop TF calibration if running
   if handles. calibrate_transfer_function.Value
       handles. calibrate_transfer_function.Value = 0;
        calibrate_transfer_function_Callback(hObject, eventdata, handles);
   end
   
   % disable transfer function calibrator
    handles.calibrate_transfer_function.Enable = 'off';
    handles.water_calibrate.Enable = 'on';
    handles.open_valve.Enable = 'on';
    handles.CleaningRoutine.Enable = 'on';
    handles.TFtype.Enable = 'on';
end

handles.traces = TotalData;
handles.timestamps = TotalTime;
handles.samplenum = samplenum;
handles.targetlevel = TargetLevel;
guidata(hObject,handles);

% --- Executes on button press in PauseSession.
function PauseSession_Callback(hObject, eventdata, handles)
if get(handles.PauseSession,'value')
    handles.Arduino.write(17, 'uint16');
    tic
    while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
    end
    if(handles.Arduino.Port.BytesAvailable == 0)
        error('arduino: Pause attempt failed')
    elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==7
        disp('arduino: Session Paused');
        set(handles.PauseSession,'String','Paused');
        set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
    end
else
    handles.Arduino.write(18, 'uint16');
    tic
    while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
    end
    if(handles.Arduino.Port.BytesAvailable == 0)
        error('arduino: UnPause attempt failed')
    elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==8
        disp('arduino: Session Resumed');
        set(handles.PauseSession,'String','Pause');
        set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    end
end
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
    [~,params] = GetSettings4Arduino(handles);
    b = fread(f,[1 + length(params) 10000],'double'); % params vector + timestamp
    fclose(f);
    
    % read TF log
    f = fopen('C:\temp_data_files\transferfunction_log.bin');
    c = fread(f,[(3+handles.TransferFunction.Data(1)) 10000],'double');
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
    if handles.useserver
        if ~exist(fileparts(server_file_name))
            mkdir(fileparts(server_file_name));
        end
    end
    % read session settings
    load('C:\temp_data_files\session_settings.mat'); % loads variable settings
    session_data = mysettings;
    session_data.timestamps = a(1,:)';
    session_data.trace = a(2:handles.NIchannels+1,:)';
    session_data.trace_legend = Connections_list();
    session_data.params = b';
    session_data.TF = c';
    session_data.ForNextSession = [handles.DAC_settings.Data' handles.TriggerHold.Data' ...
        median(handles.MeanHoldTimes.Data)...
        handles.RewardControls.Data(1) handles.TFLeftprobability.Data(1) handles.summedholdfactor.Data];
    session_data.ForNextSession_Legends = {'DAQGain', 'DAQDC', 'TriggerHoldMin', 'TriggerHoldMean', 'TriggerHoldMax', ...
        'TargetHoldMean', 'RewardHold-I', 'LeftvsRightTFs', 'SummedHoldFactor' };
    
    save(filename,'session_data*');
    display(['saved to ' filename])
    if handles.useserver
    	save(server_file_name,'session_data*');
        display(['saved to ' server_file_name])
    end
    clear a b c session_data
    set(gcf,'PaperPositionMode','auto')
    print(gcf,['C:\Users\pgupta\Desktop\','GUI_',animal_name],'-dpng','-r0');
    display(['saved GUI screen shot at ' ('C:\Users\florin\Desktop')])
    disp(['median hold = ',num2str(median(handles.MeanHoldTimes.Data)),' ms']);
    guidata(hObject, handles);
end

% --- Executes on button press in open_valve.
function open_valve_Callback(hObject, eventdata, handles)
handles.Arduino.write(80 + handles.open_valve.Value, 'uint16'); 

% --- Executes on button press in reward_now.
function reward_now_Callback(hObject, eventdata, handles)
if handles.which_stage.Value==1
    if ((handles.timestamp.Data - handles.lastrewardtime) > 20)
        handles.lastrewardtime = handles.timestamp.Data; % update 'last reward'
        handles.Arduino.write(82, 'uint16');
        %handles.Reward_Report.Data(1,3) = handles.Reward_Report.Data(1,3) + 1;
        handles.Reward_Report.Data(3) = handles.Reward_Report.Data(3) + 1;
    end
else
    handles.lastrewardtime = handles.timestamp.Data; % update 'last reward'
    handles.Arduino.write(82, 'uint16'); 
    %handles.Reward_Report.Data(1,3) = handles.Reward_Report.Data(1,3) + 1;
    handles.Reward_Report.Data(3) = handles.Reward_Report.Data(3) + 1;
end
handles.Reward_Report.Data(1) = floor(handles.Reward_Report.Data(1) + WaterPerDrop(handles));
handles.lastrewardtime = handles.timestamp.Data;
guidata(hObject, handles);

% --- Executes on button press in water_calibrate.
function water_calibrate_Callback(hObject, eventdata, handles)
handles.Arduino.write(83, 'uint16'); 

% --- Executes when entered data in editable cell(s) in RewardControls.
function RewardControls_CellEditCallback(hObject, eventdata, handles)
Send2Arduino(handles);

% --- Executes on button press in MultiRewards.
function MultiRewards_Callback(hObject, eventdata, handles)
Send2Arduino(handles);

% --- Executes when entered data in editable cell(s) in ZoneLimitSettings.
function ZoneLimitSettings_CellEditCallback(hObject, eventdata, handles)        
% compute new target definition
GetTargetDefinition(handles);
guidata(hObject,handles);
Params2File(handles);

[handles] = UpdateTransferFunction(handles);

if handles.which_perturbation.Value == 11 && ...
        mod(floor(handles.current_trial_block.Data(2)/handles.TransferFunction.Data(2)),2)
    if handles.TFtype.Value
        handles.TargetDefinition.Data = handles.TargetDefinition.Data + 2*handles.ZoneLimitSettings.Data(1);
    end
end

guidata(hObject,handles);
pause(0.1);
Send2Arduino(handles);

% --------------------------------------------------------------------

% --- Executes on button press in stay_time_up.
function stay_time_up_Callback(hObject, eventdata, handles)
handles.TargetHold.Data = handles.TargetHold.Data + 25;
handles.TargetHold.ForegroundColor = 'r';

% --- Executes on button press in stay_time_down.
function stay_time_down_Callback(hObject, eventdata, handles)
handles.TargetHold.Data = handles.TargetHold.Data - 25;
handles.TargetHold.ForegroundColor = 'r';

% --- Executes on button press in update_zones.
function update_zones_Callback(hObject, eventdata, handles)
% safety - turn motor off
handles.Arduino.write(70, 'uint16'); 
set(handles.motor_status,'String','OFF')
set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
handles.motor_home.Enable = 'off';

% update transfer function
[handles] = UpdateTransferFunction(handles);
guidata(hObject,handles);

Send2Arduino(handles);
handles.locations_per_zone.ForegroundColor = 'k';
% Hint: get(hObject,'Value') returns toggle state of update_zones

% turn motor on
handles.Arduino.write(71, 'uint16'); 
set(handles.motor_status,'String','ON')
set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
handles.motor_home.Enable = 'on';

function change_in_zones_Callback(hObject, eventdata, handles)
hObject.ForegroundColor = 'r';

% --- Executes on button press in fake_lever_signal.
function fake_lever_signal_Callback(hObject, eventdata, handles)
Send2Arduino(handles);

% --- Executes when entered data in editable cell(s) in DAC_settings.
function DAC_settings_CellEditCallback(hObject, eventdata, handles)
% safety - turn motor off
handles.Arduino.write(70, 'uint16'); 
set(handles.motor_status,'String','OFF')
set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
handles.motor_home.Enable = 'off';

[handles] = UpdateTransferFunction(handles);
guidata(hObject,handles);
Send2Arduino(handles);

% turn motor on
handles.Arduino.write(71, 'uint16'); 
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
handles.Arduino.write(90, 'uint16'); 
guidata(hObject, handles);
data = startForeground(handles.NI);
handles.DAC_levels.Data = round([min(data(:,1)) max(data(:,1))]',4,'significant');
handles.NI.DurationInSeconds = temp_duration;

% --- Executes on button press in lever_raw_on.
function lever_raw_on_Callback(hObject, eventdata, handles)
if get(handles.lever_raw_on,'Value')
    set(handles.lever_raw_on,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.lever_raw_plot,'LineStyle','none');
    %set(handles.respiration_plot,'LineStyle','none');
    %set(handles.respiration_2_plot,'LineStyle','none');
else
    set(handles.lever_raw_on,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.lever_raw_plot,'LineStyle','-');
    %set(handles.respiration_plot,'LineStyle','-');
    %set(handles.respiration_2_plot,'LineStyle','-');
end
guidata(hObject, handles);

% --- Executes on button press in respiration_on.
function respiration_on_Callback(hObject, eventdata, handles)
if get(handles.respiration_on,'Value')
    set(handles.respiration_on,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.respiration_plot,'LineStyle','none');
else
    set(handles.respiration_on,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.respiration_plot,'LineStyle','-');
end
guidata(hObject, handles);


% --- Executes on button press in lick_piezo_on.
function lick_piezo_on_Callback(hObject, eventdata, handles)
if get(handles.lick_piezo_on,'Value')
    set(handles.lick_piezo_on,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.lickpiezo_plot,'LineStyle','-');
else
    set(handles.lick_piezo_on,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.lickpiezo_plot,'LineStyle','none');
end
guidata(hObject, handles);


% --- Executes on button press in camera_sync_on.
function camera_sync_on_Callback(hObject, eventdata, handles)
if get(handles.camera_sync_on,'Value')
    set(handles.camera_sync_on,'BackgroundColor',[0.5 0.94 0.94]);
    set(handles.camerasync_plot,'LineStyle','none');
    set(handles.camerasync2_plot,'LineStyle','none');
else
    set(handles.camera_sync_on,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.camerasync_plot,'LineStyle','-');
    set(handles.camerasync2_plot,'LineStyle','-');
end
guidata(hObject, handles);


% --- Executes when entered data in editable cell(s) in TargetHold.
function TargetHold_CellEditCallback(hObject, eventdata, handles)
if hObject.Data(1)>hObject.Data(2)
    hObject.Data(1) = hObject.Data(2) - 10;
end
if hObject.Data(3)<hObject.Data(2)
    hObject.Data(3) = hObject.Data(2) + 10;
end
guidata(hObject, handles);

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
Send2Arduino(handles);

% --- Executes on button press in motor_override.
function motor_override_Callback(hObject, eventdata, handles)
handles.Arduino.write(60 + handles.motor_override.Value, 'uint16');
set(handles.motor_override,'BackgroundColor',[(0.94 - 0.44*handles.motor_override.Value) 0.94 0.94]);
if handles.motor_override.Value
    % enable direct motor controls
    handles.motor_move.Enable = 'on';
    handles.change_motor_params.Enable = 'on';
else
    % disable direct motor controls
    handles.motor_move.Enable = 'off';
    handles.change_motor_params.Enable = 'off';
end

% --- Executes on button press in motor_toggle.
function motor_toggle_Callback(hObject, eventdata, handles)
if isequal(handles.motor_status.String,'ON')
    handles.Arduino.write(70, 'uint16');
    set(handles.motor_status,'String','OFF')
    set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
else    
    handles.Arduino.write(71, 'uint16');
    set(handles.motor_status,'String','ON')
    set(handles.motor_status,'BackgroundColor',[0.5 0.94 0.94]);
end

% --- Executes on button press in motor_move.
function motor_move_Callback(hObject, eventdata, handles)
pause(0.01);
handles.Arduino.write(62, 'uint16'); % handler - move motor to specific location
% get chosen location
contents = cellstr(get(handles.all_locations,'String'));
my_location = str2num(char(contents(handles.all_locations.Value)));
handles.Arduino.write(my_location+handles.MotorLocationArduinoMax+1, 'uint16'); % which location

% --- Executes on button press in motor_home.
function motor_home_Callback(hObject, eventdata, handles)
if handles.motor_override.Value
    pause(0.01);
    handles.Arduino.write(62, 'uint16'); % handler - move motor to specific location
    handles.Arduino.write(handles.MotorLocationArduinoMax+1, 'uint16'); % home location       
else
    set(handles.motor_home,'BackgroundColor',[0.5 0.94 0.94]);
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
    handles.Arduino.write(stepsize, 'uint16');
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
        CalibrateTransferFunction(handles);
        %Update_LocationSequence(handles);
    end
else
    [handles] = UpdateTransferFunction(handles);
    guidata(hObject,handles);
    Send2Arduino(handles);
end

% --- Executes when entered data in editable cell(s) in MFC_table.
function MFC_table_CellEditCallback(hObject, eventdata, handles)
%outputSingleScan(handles.MFC,handles.MFC_table.Data');

% --- Executes on button press in Zero_MFC.
function Zero_MFC_Callback(hObject, eventdata, handles)
if ~isempty(handles.MFC)
    if handles.Zero_MFC.Value
        if strcmp(handles.Zero_MFC.String,'MFCs OFF')
            % ramp up MFCs
            handles.Zero_MFC.String = '.......';
            MFC_ramp(handles);
            handles.Zero_MFC.String = 'MFCs ON';
            odor_vial_Callback(hObject, eventdata, handles);
        end
    else
        outputSingleScan(handles.MFC,0*handles.MFC_table.Data');
        handles.Zero_MFC.String = 'MFCs OFF';
    end
end

% --- Executes on button press in air_to_manifold.
function air_to_manifold_Callback(hObject, eventdata, handles)
handles.Arduino.write(56 + handles.air_to_manifold.Value, 'uint16'); 
if handles.air_to_manifold.Value
    set(handles.air_to_manifold,'String','Air ON')
    set(handles.air_to_manifold,'BackgroundColor',[0.5 0.94 0.94]);
else
    set(handles.air_to_manifold,'String','Air OFF')
    set(handles.air_to_manifold,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in Vial3.
function Vial2Manifold_Callback(hObject, eventdata, handles)
if ~isempty(eventdata)
    if strcmp(eventdata.Source.Tag,'odor_to_manifold')
        MyVial = find([handles.Vial0.Value handles.Vial1.Value handles.Vial2.Value handles.Vial3.Value]);
    else
        MyVial = 1 + str2num(eventdata.Source.Tag(end));
    end
else
    MyVial = 1;
end
MyVial = handles.odor_to_manifold.Value * MyVial;
handles.Arduino.write(50 + MyVial, 'uint16'); 
if handles.odor_to_manifold.Value
    set(handles.odor_to_manifold,'String','odor ON')
    set(handles.odor_to_manifold,'BackgroundColor',[0.5 0.94 0.94]);
else
    set(handles.odor_to_manifold,'String','odor OFF')
    set(handles.odor_to_manifold,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in odor_vial.
function odor_vial_Callback(hObject, eventdata, handles)
UpdateOdorVials(handles);
if handles.odor_vial.Value && ~isempty(handles.Odor_list.Value)
    set(handles.odor_vial,'String','Vials ON');
    set(handles.odor_vial,'BackgroundColor',[0.5 0.94 0.94]);
else
    set(handles.odor_vial,'String','Vials OFF');
    set(handles.odor_vial,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in CleaningRoutine.
function CleaningRoutine_Callback(hObject, eventdata, handles)
if handles.CleaningRoutine.Value    
    % turn on all the odor vials, and shut off airflow to manifold
    handles.Odor_list.Value = [1 2 3 4];
    handles.odor_vial.Value = 1;
    handles.odor_to_manifold.Value = 0;
    handles.air_to_manifold.Value = 0;
    guidata(hObject,handles);
    Vial2Manifold_Callback(hObject, eventdata, handles);
    odor_vial_Callback(hObject, eventdata, handles);
    
    handles.Arduino.write(13, 'uint16');
    tic
    while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
    end
    if(handles.Arduino.Port.BytesAvailable == 0)
        error('arduino: failed to start cleaning')
    elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==3
        disp('arduino: Cleaning Routine Started');
    end
    
    set(handles.CleaningRoutine,'String','Cleaning...')
    set(handles.CleaningRoutine,'BackgroundColor',[0.5 0.94 0.94]);
    
else
    handles.Arduino.write(14, 'uint16');
    tic
    while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
    end
    if(handles.Arduino.Port.BytesAvailable == 0)
        error('arduino: failed to stop cleaning')
    elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==4
        disp('arduino: Cleaning Routine Stopped');
    end
    
    % turn on all the odor vials, and shut off airflow to manifold
    handles.Odor_list.Value = [2 3 4];
    handles.odor_vial.Value = 0;
    handles.odor_to_manifold.Value = 0;
    handles.air_to_manifold.Value = 0;
    guidata(hObject,handles);
    Vial2Manifold_Callback(hObject, eventdata, handles);
    odor_vial_Callback(hObject, eventdata, handles);
    
    set(handles.CleaningRoutine,'String','Cleaning OFF')
    set(handles.CleaningRoutine,'BackgroundColor',[0.94 0.94 0.94]);
end

% --- Executes on button press in startStopCamera.
function startStopCamera_Callback(hObject, eventdata, handles)
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

% --- Executes on selection change in focus_mode.
function focus_mode_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String')); % returns focus_mode contents as cell array
%handles.mycam.FocusMode = contents{get(hObject,'Value')}; %returns selected item from focus_mode
handles.focus_value.Data = handles.mycam.Focus;
if get(hObject,'Value') == 1
    handles.focus_value.Enable = 'off';
else
    handles.focus_value.Enable = 'on';
end

% --- Executes on selection change in exposure_mode.
function exposure_mode_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String')); % returns focus_mode contents as cell array
handles.mycam.ExposureMode = contents{get(hObject,'Value')}; %returns selected item from focus_mode
handles.Exposure.Data = handles.mycam.Exposure;
if get(hObject,'Value') == 1
    handles.focus_value.Enable = 'off';
else
    handles.focus_value.Enable = 'on';
end

% --- Executes on slider movement.
function Adjust_Zoom_Callback(hObject, eventdata, handles)
handles.mycam.Zoom = hObject.Value;

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

% --- Executes when entered data in editable cell(s) in exposure_value.
function exposure_value_CellEditCallback(hObject, eventdata, handles)
if (hObject.Data>=-11) && (hObject.Data<=-2)
    %handles.mycam.Focus = hObject.Data;
elseif (hObject.Data<-11)
    hObject.Data = -11;
else
    hObject.Data = -2;
end
handles.mycam.Exposure = hObject.Data;

% --- Executes on button press in close_gui.
function close_gui_Callback(hObject, eventdata, handles)
% close valves and MFCs
if ~isempty(handles.MFC)
    outputSingleScan(handles.MFC,0*handles.MFC_table.Data');
end
handles.Arduino.write(56, 'uint16'); % turn air valve off
delete(handles.figure1);
handles.Arduino.write(12, 'uint16');
tic
while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
end
if(handles.Arduino.Port.BytesAvailable == 0)
    handles.Arduino.close;
    error('arduino: arduino did not send confirmation byte in time')
end
if handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==7
    handles.Arduino.close;
    disp('arduino: disconnected, handshake successful');
else
    handles.Arduino.close;
    disp('arduino: disconnected, handshake unsuccessful');
end

% --- Executes on button press in log_weight.
function log_weight_Callback(hObject, eventdata, handles)

% check if the weight log file exists
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
foldername_server = char(handles.file_names.Data(3));

MadeNewFile = 0;
FileExistChecker = 0;
while ~FileExistChecker
    filename = [foldername_local, filesep, animal_name, '_WeightLog.mat'];
    [~,justname] = fileparts(filename);
    server_file_name = [foldername_server,filesep,justname,'.mat'];
    
    if ~exist(filename) %#ok<*EXIST>
        % get weight
        prompt = {'Enter original weight (grams):', 'Enter current weight (grams):'};
        dlg_title = 'Weight Log';
        num_lines = 2;
        defaultans = {num2str(23), num2str(23)};
        userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if ~isempty(userans)
            weight(1,:) = {datestr(now, 'yyyymmdd'), datestr(now, 'HH:MM:SS'), char(userans(1))};
            weight(2,:) = {datestr(now, 'yyyymmdd'), datestr(now, 'HH:MM:SS'), char(userans(2))};
            save(filename,'weight*');
            if handles.useserver
                save(server_file_name,'weight*');
            end
            MadeNewFile = 1;
            w_o = str2num(char(userans(1)));
            w_c = str2num(char(userans(2)));
            w_p = round(100*w_c/w_o,0,'decimals');
            handles.WeightString.String = [num2str(w_p),'%,  ', num2str(w_c), ' grams,  [85% = ', num2str(0.85*w_o), ' grams]'];
        end
    end
    FileExistChecker = exist(filename,'file');
end
    
if ~MadeNewFile
    clear weight;
    load(filename);
    if ~isempty(strmatch(datestr(now, 'yyyymmdd'),weight(:,1)))
        % check with the use if he/she wants to make a repeat entry
        prompt = {'A weight entry for today already exists. You can still add a new one or cancel'};
        dlg_title = 'Weight Log';
        num_lines = 1;
        defaultans = weight(end,3);
        userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if ~isempty(userans)
            weight(end+1,:) = {datestr(now, 'yyyymmdd'), datestr(now, 'HH:MM:SS'), char(userans)};
            save(filename,'weight*');
            if handles.useserver
                save(server_file_name,'weight*');
            end
            w_o = str2num(char(weight(1,3)));
            w_c = str2num(char(userans));
            w_p = round(100*w_c/w_o,0,'decimals');
            handles.WeightString.String = [num2str(w_p),'%,  ', num2str(w_c), ' grams,  [85% = ', num2str(0.85*w_o), ' grams]'];
        else
            w_o = str2num(char(weight(1,3)));
            w_c = str2num(char(weight(end,3)));
            w_p = round(100*w_c/w_o,0,'decimals');
            handles.WeightString.String = [num2str(w_p),'%,  ', num2str(w_c), ' grams,  [85% = ', num2str(0.85*w_o), ' grams]'];
        end
    else
        % check with the use if he/she wants to make a repeat entry
        prompt = {'Please enter weight (in grams)'};
        dlg_title = 'Weight Log';
        num_lines = 1;
        defaultans = weight(end,3);
        userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if ~isempty(userans)
            weight(end+1,:) = {datestr(now, 'yyyymmdd'), datestr(now, 'HH:MM:SS'), char(userans)};
            save(filename,'weight*');
            if handles.useserver
                save(server_file_name,'weight*');
            end
            w_o = str2num(char(weight(1,3)));
            w_c = str2num(char(userans));
            w_p = round(100*w_c/w_o,0,'decimals');
            handles.WeightString.String = [num2str(w_p),'%,  ', num2str(w_c), ' grams,  [85% = ', num2str(0.85*w_o), ' grams]'];
        end
    end
end

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

% --- Executes when entered data in editable cell(s) in TargetsActive.
function TargetsActive_CellEditCallback(hObject, eventdata, handles)
handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
guidata(hObject, handles);

% --- Executes when entered data in editable cell(s) in PerturbationSettings.
function PerturbationSettings_CellEditCallback(hObject, eventdata, handles)
global TrialsToPerturb;
if handles.PerturbationSettings.Data(1) > 0
    TrialsToPerturb = zeros(1,ceil(1/handles.PerturbationSettings.Data(1)));
    TrialsToPerturb(1) = 1;
end

% --- Executes on button press in PseudoRandomZones.
function PseudoRandomZones_Callback(hObject, eventdata, handles)

% --- Executes on button press in preloaded_sequence.
function preloaded_sequence_Callback(hObject, eventdata, handles)

% --- Executes on button press in adaptive_holds.
function adaptive_holds_Callback(hObject, eventdata, handles)

% --- Executes on button press in odor_priors.
function odor_priors_Callback(hObject, eventdata, handles)

% --- Executes on button press in TFtype.
function TFtype_Callback(hObject, eventdata, handles)


