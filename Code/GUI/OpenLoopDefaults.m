function [handles] = OpenLoopDefaults(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>

handles.PIDMode.Value = 1;

switch char(handles.computername)
    case {'JUSTINE'}
        % files and paths
        handles.file_names.Data(2) = {'C:\Data\Behavior'};
        handles.file_names.Data(3) = {'\\grid-hs\albeanu_nlsas_norepl_data\pgupta\Behavior'};
        handles.useserver = 1;
        
        % Rates
        handles.DAQrates.Data = [500 20]';
        
        % sensors and scaling
        handles.DAC_settings.Data = [2.0 2.5]';
        handles.RS_scaling.Data = [0.5 6.5]';
        handles.RE_scaling.Data = [1 0]';
        handles.LickPiezo.Data = [0.2 6]';
        %handles.LickTicks.Data = [0.1 6]';
        handles.lever_raw_on.Value = 1; % hide extra traces
        handles.respiration_on.Value = 0;
        handles.lick_piezo_on.Value = 1; 
        handles.camera_sync_on.Value = 1;
        %handles.watercoeffs = [0.00134 0.0515 0.099]; % water per drop
        handles.watercoeffs = [0.0006286 0.09254 0.918]; % water per drop
        handles.fliphome = 1; 
        
        % default params
        handles.TrialSettings.Data = [50 500 500 50 500 500]'; % motor-settle, pre-odor, odor, purge, post-odor, ITI
        handles.Odor_list.Value = 1 + [1 2 3]'; % active odors
        handles.openloop = 1; % Run in open-loop mode
        handles.Odor_list.Value = 1 + [0 1 2 3]'; % active odors
        
        % Transfer function
        handles.TFtype.Value = 1; % 1 = fix speed, 0 = fixed start
        handles.TFtype.Enable = 'on';
        
        % manifold and motor
        handles.MotorLocations = 115; % currently used for variable gain
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsFixSpeed = 100; % for fix speed
        handles.ManifoldOutlets = 24; % 32 in total - out of which only 24 are used
        handles.motor_params = 4; % motor step size
        
        % currently unused settings
        handles.MFC_table.Data = [1.6 0.64]'; %[1.6 0.4]';
        handles.Zero_MFC.Value = 0;
        handles.which_stage.Value = 3; % training stage
        handles.TransferFunction.Data(2) = 100; % block size (1 = no blocks)
        
        
    case {'marbprec', 'PRIYANKA-HP'}
        % files and paths
        handles.file_names.Data(2) = {'C:\Data\OpenLoop'};
        handles.file_names.Data(3) = {'\\grid-hs\albeanu_nlsas_norepl_data\pgupta\OpenLoop'};
        
        % Rates
        handles.DAQrates.Data = [500 20]';
        
        % sensors and scaling
        handles.DAC_settings.Data = [1.75 2.10]';
        handles.RS_scaling.Data = [-1 5.5]';
        handles.fliphome = 0;
        
        % default params
        handles.TrialSettings.Data = [50 500 500 50 500 500]'; % motor-settle, pre-odor, odor, purge, post-odor, ITI
        handles.Odor_list.Value = 1 + [1 2 3]'; % active odors
        handles.openloop = 1; % Run in open-loop mode
        
        % Transfer function
        handles.TFtype.Value = 1; % 1 = fix speed, 0 = fixed start
        handles.TFtype.Enable = 'on';
        
        % manifold and motor
        handles.MotorLocations = 115; % currently used for variable gain
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsFixSpeed = 100; % for fix speed
        handles.ManifoldOutlets = 24; % 32 in total - out of which only 24 are used
        handles.motor_params = 4; % motor step size
        
    case {'PRIYANKA-PC','DESKTOP-05QAM9D'}
        handles.file_names.Data(2) = {'C:\Data\OpenLoop'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\OpenLoop'};
        handles.ManifoldOutlets = 16;
        % motor location settings
        handles.motor_params = 4;
        % Trial settings
        handles.TrialSettings.Data = [50 500 500 50 500 500]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        handles.MotorLocations = 120;
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsRange = 140;
        handles.fliphome = 1;         
end
end