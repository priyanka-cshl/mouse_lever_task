function varargout = OpenLoopOdorLocator(varargin)

% OPENLOOPODORLOCATOR MATLAB code for OpenLoopOdorLocator.fig (GUI)
%      OPENLOOPODORLOCATOR, by itself, creates a new OPENLOOPODORLOCATOR or raises the existing
%      singleton*.
%
%      H = OPENLOOPODORLOCATOR returns the handle to a new OPENLOOPODORLOCATOR or the handle to
%      the existing singleton*.
%zeros
%      OPENLOOPODORLOCATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPENLOOPODORLOCATOR.M with the given input arguments.
%
%      OPENLOOPODORLOCATOR('Property','Value',...) creates a new OPENLOOPODORLOCATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OpenLoopOdorLocator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OpenLoopOdorLocator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OpenLoopOdorLocator

% Last Modified by GUIDE v2.5 26-Jan-2020 12:08:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OpenLoopOdorLocator_OpeningFcn, ...
                   'gui_OutputFcn',  @OpenLoopOdorLocator_OutputFcn, ...
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

% --- Executes just before OpenLoopOdorLocator is made visible.
function OpenLoopOdorLocator_OpeningFcn(hObject, eventdata, handles, varargin)
% basic housekeeping
handles.output = hObject;
handles.mfilename = mfilename;
handles.startAcquisition.Enable = 'off';

% rig specific settings
handles.computername = textread(fullfile(fileparts(mfilename('fullpath')),'hostname.txt'),'%s');
handles.useserver = 1;
[handles] = OpenLoopDefaults(handles);

% clear indicators
handles.current_trial_block.Data(1:7,1) = zeros(7,1);
handles.Date.String = datestr(now, 'mm-dd-yy');
handles.StartTime.Visible = 'off';
handles.StopTime.Visible = 'off';

% load mouse specific settings
handles.file_names.Data(1) = {varargin{1}}; %#ok<CCAT1>
% create the data directories if they don't already exist
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
foldername_server = char(handles.file_names.Data(3));
if ~exist(fullfile(foldername_local,animal_name),'dir')
    mkdir(fullfile(foldername_local,animal_name));
    disp('making local data directory');
end
if handles.useserver
    if ~exist(fullfile(foldername_server,animal_name),'dir')
        mkdir(fullfile(foldername_server,animal_name));
        disp('making remote data directory');
    end
end

%% set up NI acquisition and reset Arduino
handles.sampling_rate_array = handles.DAQrates.Data;
[handles.NI,handles.MFC,handles.Channels,handles.NIchannels] = configure_NIDAQ(handles);
handles.Arduino = configure_ArduinoMain(handles);

%% Files - for data logging
handles.was_last_file_saved = 1;
handles.traces = zeros(5,5);
handles.timestamps = ones(5,1)*-1;
handles.samplenum = 1;
handles.targetLevel = zeros(2,2);
handles.update_call = 0;

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
handles.stimulus_plot = plot(NaN, NaN, 'color',Plot_Colors('r')); % target odor location (rotary encoder)
handles.thermistor_plot = plot(NaN, NaN, 'color',Plot_Colors('r')); % target odor location (rotary encoder)
handles.in_reward_zone_plot = fill(NaN,NaN,Plot_Colors('o'));
handles.in_reward_zone_plot.EdgeColor = 'none';
handles.lick_plot = plot(NaN, NaN, 'color',Plot_Colors('r'),'Linewidth',1); %licks
handles.homesensor_plot = plot(NaN, NaN,'k'); %homesensor
handles.respiration_plot = plot(NaN, NaN, 'color',Plot_Colors('t')); % respiration sensor
handles.lickpiezo_plot = plot(NaN, NaN, 'color',Plot_Colors('p')); % lick piezo
handles.reward_plot = plot(NaN, NaN, 'color',Plot_Colors('t'),'Linewidth',1.25); %rewards
handles.camerasync_plot = plot(NaN, NaN, 'color',Plot_Colors('pl'),'Linewidth',1); %point-grey cam sync
handles.camerasync2_plot = plot(NaN, NaN, 'color',Plot_Colors('pd'),'Linewidth',1); %point-grey cam sync

set(handles.axes1,'YLim',handles.Plot_YLim.Data);

axes(handles.axes9); % Transfer function plot
handles.TF_plot = ...
    imagesc(((-handles.MotorLocationsFixSpeed:1:handles.MotorLocationsFixSpeed)')/...
    handles.MotorLocationsFixSpeed,[-1 1]);
colormap(brewermap([handles.ManifoldOutlets],'rdbu'));
axis off tight
set(handles.axes9,'YLim',[0 100]);

axes(handles.axes4); % motor location plot
handles.motor_location = plot([1],[2],'r<','MarkerFaceColor','k','MarkerEdgeColor','k');
axis off tight
set(handles.axes4,'YLim',[0 100]);
set(handles.axes4, 'Color', 'none');

axes(handles.axes16); % drive depth plot
handles.depthofinterest = line([0 0],[2.2 3.5],'color','r','LineWidth',2);
hold on
handles.drivedepth = plot(0.5, 2.5,'r<','MarkerFaceColor','k','MarkerEdgeColor','k');
set(handles.axes16, 'Fontsize', 6, 'Color', [0.94 0.94 0.94], 'box', 'off', 'Linewidth', 1.5, 'TickLength', [0.02 0.025], 'TickDir', 'out');
set(handles.axes16, 'XLim', [0 1], 'XTick',[],'XColor',[0.94 0.94 0.94], 'YLim',[0 4], 'YTick',[0:1:4], 'YDir','reverse');
axis manual

GetCurrentDepth(hObject, eventdata, handles);

% for webcam
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
       case {'PRIYANKA-PC','DESKTOP-05QAM9D'}
            handles.mycam = webcam(2);% {'USB}2.0 PC CAMERA', 'USB Video Device'}
            handles.mycam.Resolution = handles.mycam.AvailableResolutions{1};
            handles.camera_available = 1;
    end
end
% display webcam image, if available
axes(handles.cameraAxes);
if handles.camera_available
    handles.cam_image = image(snapshot(handles.mycam),'parent',handles.cameraAxes);
end
set(handles.cameraAxes,'XTick',[],'XTickLabel',' ','XTickMode','manual','XTickLabelMode','manual');
set(handles.cameraAxes,'YTick',[],'YTickLabel',' ','YTickMode','manual','YTickLabelMode','manual');

% Update handles structure
guidata(hObject, handles);
calibrate_DAC_Callback(hObject,eventdata,handles);
SessionSettings_CellEditCallback(hObject, eventdata, handles);
UpdateAllPlots(hObject,eventdata,handles);
Update_Callback(hObject,eventdata,handles); % auto calls Update_Params

% set up odors
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

% disable motor override
handles.motor_override.Value = 0;
motor_override_Callback(hObject, eventdata, handles);
handles.startAcquisition.Enable = 'on';
warning('off','MATLAB:callback:error');

% --- Outputs from this function are returned to the command line.
function varargout = OpenLoopOdorLocator_OutputFcn(hObject, eventdata, handles)  %#ok<*INUSL>
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
        
        % set up trial sequence
        [handles] = SetUpOpenLoopTrials(handles);
        %guidata(hObject,handles);
        mysettings.TrialSequence = handles.TrialSequence;
        % main settings - only change in the beginning of each session
        [mysettings.legends, mysettings.params] = OpenLoop_Settings(handles);
        save('C:\temp_data_files\session_settings.mat','mysettings*');
        
        % dynamic settings - change within a session
        handles.settingsfileID = fid2;
        fwrite(fid2,[handles.timestamp.Data mysettings.params],'double');
        
        handles.hObject = hObject;
        handles.traces = zeros(6000,handles.NIchannels); %???500*60*60*4
        handles.timestamps = -ones(6000,1);
        handles.samplenum = 1;
        handles.write = 1;
        TotalData = handles.traces;
        TotalTime = handles.timestamps;
        samplenum = handles.samplenum;

        set(handles.startAcquisition,'String','Running');
        set(hObject,'BackgroundColor',[0.5 0.94 0.94]);
        time = regexp(char(datetime('now')),' ','split');
        handles.Date.String = datestr(now, 'mm-dd-yy');
        handles.StartTime.String = char(time(2));
        handles.StartTime.Visible = 'on';
        handles.StopTime.Visible = 'off';

        % clear indicators
        handles.current_trial_block.Data([2 4 5 6 7],1) = 0;
        handles.current_trial_block.Data(2,1) = 1;
        handles.update_call = 1;
        handles.timestamp.Data = 0;
        
        % clear plots
        handles.trial_on.Vertices = [];
        handles.trial_on.Faces = [];
        handles.in_reward_zone_plot.Vertices = [];
        handles.in_reward_zone_plot.Faces = [];
        set(handles.stimulus_plot,'XData',NaN,'YData',NaN);
        set(handles.respiration_plot,'XData',NaN,'YData',NaN);
        set(handles.lickpiezo_plot,'XData',NaN,'YData',NaN);
        set(handles.lick_plot,'XData',NaN,'YData',NaN);
        
        % open odor vials
        %handles.Odor_list.Value = 1 + [0 1 2 3]'; % active odors
        handles.odor_vial.Value = 1;
        odor_vial_Callback(hObject, eventdata, handles);
        handles.odor_to_manifold.Value = 1;
        handles.air_to_manifold.Value = 0;
        Vial2Manifold_Callback(hObject, eventdata, handles);
        
        tstart = tic;
        
        % update motor stepsize 
        % different for fixgain (stepsize = 2) vs. variable gain (stepsize = 1)
        handles.CleaningRoutine.Value = 0;
        handles.CleaningRoutine.Enable = 'off';
        handles.TFtype.Enable = 'off';
        handles.Arduino.write(73 + handles.TFtype.Value,'uint16');
        
        % Calibrate Rotary encoder
        handles = CalibrateRotaryEncoder(handles);
        % disable motor override
        handles.motor_override.Value = 0;
        motor_override_Callback(hObject, eventdata, handles);
        % enable the motors
        set(handles.motor_status,'String','OFF')
        motor_toggle_Callback(hObject, eventdata, handles);
        
        while toc(tstart) < handles.odor_build_up.Data
            %disp(toc(tstart));
        end
        
        % start the Arduino timer
        handles.Arduino.write(15, 'uint16'); 
        tic
        while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
        end
        if(handles.Arduino.Port.BytesAvailable == 0)
            error('arduino: Motor Timer Start did not send confirmation byte')
        elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==8
            disp('arduino: Motor Timer Started');
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
        
        NewOpenLoopTrial_Callback(handles);
        
        % update pointer to match motor location
        handles.axes4.YLim = [0 size(handles.all_locations.String,1)];
        handles.motor_location.YData = MapRotaryEncoderToTFColorMapOpenLoop(handles, handles.Rotary.Limits(3));
       
        handles.lis = handles.NI.addlistener('DataAvailable', @(src,evt) OpenLoopNI_Callback(src,evt,handles,hObject,fid1));
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
   
   % close odor vials
   handles.odor_vial.Value = 0;
   odor_vial_Callback(hObject, eventdata, handles);
   
   % stop the Arduino timer
   handles.Arduino.write(16, 'uint16');
   tic
   while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
   end
   if(handles.Arduino.Port.BytesAvailable == 0)
       error('arduino: Motor Timer Stop did not send confirmation byte')
   elseif handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==9
       disp('arduino: Motor Timer Stopped');
   end

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
    
%     % read settings log
%     f = fopen('C:\temp_data_files\settings_log.bin');
%     %[~,params1] = Current_Settings(handles,0);
%     %[~,params2] = Current_Settings(handles,1);
%     [~,params1] = OpenLoop_Settings(0);
%     b = fread(f,[1 + length(params1)+length(params2) 10000],'double'); % params vector + timestamp
%     fclose(f);
    
%     % read TF log
%     f = fopen('C:\temp_data_files\transferfunction_log.bin');
%     c = fread(f,[(3+handles.TransferFunction.Data(1)) 10000],'double');
%     fclose(f);
    
    % filename for writing data
    animal_name = char(handles.file_names.Data(1));
    foldername_local = char(handles.file_names.Data(2));
    foldername_server = char(handles.file_names.Data(3));
    
    FileExistChecker = 1;
    run_num = 0;
    
    while FileExistChecker
        filename = [foldername_local, filesep, animal_name, filesep, ...
            animal_name, '_', datestr(now, 'yyyymmdd'), ['_o' num2str(run_num) ], '.mat'];
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
%        mkdir(fileparts(server_file_name));
    end
    % read session settings
    load('C:\temp_data_files\session_settings.mat'); % loads variable settings
    session_data = mysettings;
    session_data.timestamps = a(1,:)';
    session_data.trace = a(2:handles.NIchannels+1,:)';
    session_data.trace_legend = Connections_list();
    session_data.odor_buildup = handles.odor_build_up.Data;
    
%     session_data.params = b';
%     session_data.TF = c';
%     session_data.ForNextSession = [handles.DAC_settings.Data' handles.TriggerHold.Data' handles.RewardControls.Data(3) handles.TFLeftprobability.Data(1) handles.summedholdfactor.Data];
%     session_data.ForNextSession_Legends = {'DAQGain', 'DAQDC', 'TriggerHoldMin', 'TriggerHoldMean', 'TriggerHoldMax', 'RewardHold-II', 'LeftvsRightTFs', 'SummedHoldFactor' };
    
    save(filename,'session_data*');
    display(['saved to ' filename])
    if handles.useserver
        save(server_file_name,'session_data*');
        display(['saved to ' server_file_name])
    end
    clear a b c session_data
%     set(gcf,'PaperPositionMode','auto')
%     print(gcf,['C:\Users\pgupta\Desktop\','GUI_',animal_name, '_', datestr(now, 'yyyymmdd'), '_r' num2str(run_num)],...
%         '-dpng','-r0');
%     display(['saved GUI screen shot at ' ('C:\Users\florin\Desktop')])
    guidata(hObject, handles);
end

% --- Executes when entered data in editable cell(s) in ZoneLimitSettings.
function Update_Callback(hObject, eventdata, handles)        
Update_OpenLoopParams(handles);

% --- Executes when entered data in editable cell(s) in DAC_settings.
function DAC_settings_CellEditCallback(hObject, eventdata, handles)
% safety - turn motor off
handles.Arduino.write(70, 'uint16'); 
set(handles.motor_status,'String','OFF')
set(handles.motor_status,'BackgroundColor',[0.94 0.94 0.94]);
handles.motor_home.Enable = 'off';

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

% --- Executes on button press in motor_override.
function motor_override_Callback(hObject, eventdata, handles)
% hObject    handle to motor_override (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
handles.Arduino.write(my_location+handles.MotorLocations+1, 'uint16'); % which location

% --- Executes on button press in motor_home.
function motor_home_Callback(hObject, eventdata, handles)
if handles.motor_override.Value
    pause(0.01);
    handles.Arduino.write(62, 'uint16'); % handler - move motor to specific location
    handles.Arduino.write(handles.MotorLocations+1, 'uint16'); % home location       
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

% --- Executes on button press in close_gui.
function close_gui_Callback(hObject, eventdata, handles)
delete(handles.figure1);
handles.Arduino.write(16, 'uint16');
tic
while (handles.Arduino.Port.BytesAvailable == 0 && toc < 2)
end
if(handles.Arduino.Port.BytesAvailable == 0)
    handles.Arduino.close;
    error('arduino: arduino did not send confirmation byte in time')
end
if handles.Arduino.read(handles.Arduino.Port.BytesAvailable/2, 'uint16')==9
    handles.Arduino.close;
    disp('arduino: disconnected, handshake successful');
else
    handles.Arduino.close;
    disp('arduino: disconnected, handshake unsuccessful');
end

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

% --- Executes when entered data in editable cell(s) in SessionSettings.
function SessionSettings_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to SessionSettings (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
if handles.SessionSettings.Data(3)
    all_locations = -handles.SessionSettings.Data(2):handles.SessionSettings.Data(3):handles.SessionSettings.Data(2);
else
    all_locations = handles.SessionSettings.Data(2); % only one location;
end
handles.TF_plot.CData = flipud(all_locations')/handles.MotorLocations;
set(handles.axes9,'YLim',[0 length(handles.TF_plot.CData)]);
handles.all_locations.String = num2str(all_locations');


% --- Executes on button press in TFtype.
function TFtype_Callback(hObject, eventdata, handles)
% hObject    handle to TFtype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TFtype


% --- Executes on button press in reward_now.
function reward_now_Callback(hObject, eventdata, handles)
% hObject    handle to reward_now (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Arduino.write(82, 'uint16'); 


% --- Executes on button press in PIDMode.
function PIDMode_Callback(hObject, eventdata, handles)
% hObject    handle to PIDMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PIDMode

function PlotToggles_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to PlotToggles (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data

%for i = 1:7
if eventdata.NewData
    MyLineStyle = '-';
else
    MyLineStyle = 'none';
end
switch eventdata.Indices(1)
    case 1 % Lever Raw
        set(handles.lever_raw_plot,'LineStyle',MyLineStyle);
    case 2
        set(handles.stimulus_plot,'LineStyle',MyLineStyle);
    case 3
        set(handles.respiration_plot,'LineStyle',MyLineStyle);
    case 4
        set(handles.thermistor_plot,'LineStyle',MyLineStyle);
    case 5
        set(handles.lickpiezo_plot,'LineStyle',MyLineStyle);
    case 6
    case 7
        set(handles.camerasync_plot,'LineStyle',MyLineStyle);
        set(handles.camerasync2_plot,'LineStyle',MyLineStyle);
end
%end
% handles    structure with handles and user data (see GUIDATA)

function UpdateAllPlots(hObject,eventdata,handles)
for i = 1:7
    if handles.PlotToggles.Data(i)
        MyLineStyle = '-';
    else
        MyLineStyle = 'none';
    end
    switch i
        case 1 % Lever Raw
            %set(handles.lever_raw_plot,'LineStyle',MyLineStyle);
        case 2
            set(handles.stimulus_plot,'LineStyle',MyLineStyle);
        case 3
            set(handles.respiration_plot,'LineStyle',MyLineStyle);
        case 4
            set(handles.thermistor_plot,'LineStyle',MyLineStyle);
        case 5
            set(handles.lickpiezo_plot,'LineStyle',MyLineStyle);
        case 6
        case 7
            set(handles.camerasync_plot,'LineStyle',MyLineStyle);
            set(handles.camerasync2_plot,'LineStyle',MyLineStyle);
    end
end

% --- Executes on button press in SetDepthParams.
function SetDepthParams_Callback(hObject, eventdata, handles)
% hObject    handle to SetDepthParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% check if the weight log file exists
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
foldername_server = char(handles.file_names.Data(3));

MadeNewFile = 0;
FileExistChecker = 0;

while ~FileExistChecker
    filename = [foldername_local, filesep, animal_name, '_DepthLog.mat'];
    [~,justname] = fileparts(filename);
    server_file_name = [foldername_server,filesep,justname,'.mat'];
    
    if ~exist(filename) %#ok<*EXIST>
        % get current depth, and coordinates of interest
        prompt = {'minimum depth:', 'maximum depth:', 'turn pitch:', 'current depth:'};
        dlg_title = 'Enter depth parameters (um from surface)';
        num_lines = 4;
        defaultans = {num2str(2200), num2str(3500), num2str(150), num2str(1500)};
        userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if ~isempty(userans)
            % save params (minimum depth, max depth, turn pitch and current
            % depth
            for i = 1:4
                depth.params(i) = str2double(userans(i));
            end
            
            % make the first entry
            depth.log(1,:) = {datestr(now, 'yyyymmdd'), datestr(now, 'HH:MM:SS'), char(userans(4))};
            
            % update graph
            handles.axes16.Visible = 'on';
            handles.depthofinterest.YData = depth.params(1:2)/1000;
            handles.drivedepth.YData = str2double(char(userans(4)))/1000; 
            save(filename,'depth*');
            if handles.useserver
                save(server_file_name,'depth*');
            end
            MadeNewFile = 1;
        else
            break;
        end
    end
    FileExistChecker = exist(filename,'file');
end

if ~MadeNewFile && FileExistChecker
    clear depth;
    load(filename);
    if ~isempty(strmatch(datestr(now, 'yyyymmdd'),depth.log(:,1)))
        % check with the use if he/she wants to make a repeat entry
        dlg_title = 'A depth entry for today already exists. You can still add more turns or cancel';
    else
        dlg_title = 'Drive depth Log';
    end
    prompt = {'current depth:', 'turns to add:'}; %, 'turns to subtract:'};
    num_lines = 2;
    currentdepth = depth.log(end,3);
    defaultans = {char(currentdepth), '+0.25'};
    userans = inputdlg(prompt,dlg_title,num_lines,defaultans);
    
    if ~isempty(userans) % user wants to update
        newdepth = str2double(char(currentdepth)) + depth.params(3)*str2double(userans(2));
        depth.log(end+1,:) = {datestr(now, 'yyyymmdd'), datestr(now, 'HH:MM:SS'), char(num2str(newdepth))};
        handles.drivedepth.YData = newdepth/1000;
        save(filename,'depth*');
        if handles.useserver
            save(server_file_name,'depth*');
        end
    else % user pressed cancel
    end
    
end

function GetCurrentDepth(hObject, eventdata, handles)
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
foldername_server = char(handles.file_names.Data(3));

filename = [foldername_local, filesep, animal_name, '_DepthLog.mat'];

if  exist(filename) %#ok<*EXIST>
    clear depth;
    load(filename);
    handles.axes16.Visible = 'on';
    handles.depthofinterest.YData = depth.params(1:2)/1000;
    handles.drivedepth.YData = str2double(char(depth.log(end,3)))/1000; 
else
    handles.axes16.Visible = 'off';
    handles.depthofinterest.YData = NaN*handles.depthofinterest.YData;
    handles.drivedepth.YData = NaN*handles.drivedepth.YData;
    
end
