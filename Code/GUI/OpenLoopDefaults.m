function [handles] = OpenLoopDefaults(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>

% common to all Rigs
% Run by default in OpenLoop Acquisition Mode
handles.PIDMode.Value = 0; % acquire PID (or other external analog signals on ai13) instead of Lick Piezo (ai12)

% files and paths
handles.file_names.Data(2) = {'C:\Data\Behavior'};
handles.file_names.Data(3) = {'\\grid-hs\albeanu_nlsas_norepl_data\pgupta\Behavior'};

% Rates
handles.DAQrates.Data = [500 20]';

% default params
handles.TrialSettings.Data = [500 1000 1000 100 900 500]'; % motor-settle, pre-odor, odor, purge, post-odor, ITI
handles.openloop = 1; % Run in open-loop mode
handles.Odor_list.Value = 1 + [0 1 2 3]'; % active odors
handles.SessionSettings.Data = [5 90 15]'; % #repeats, max location, location step

% Transfer function
handles.TFtype.Value = 1; % 1 = fix speed, 0 = fixed start
handles.TFtype.Enable = 'off';
        
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
handles.TransferFunction.Data(2) = 100; % block size (1 = no blocks)'
handles.DoSequence.Value = 0;
handles.PseudoSequence.Value = 0;
        
switch char(handles.computername)
    
    case {'JUSTINE'} % Rig 2
        handles.useserver = 1; % change to zero if there's a network issue
        
        % sensors and scaling
        handles.DAC_settings.Data = [2.0 2.15]';
        
        % Plots
        handles.PlotSettings.Data(:,1) = [NaN 1 0.5 2 0.2 NaN NaN]; % gains
        handles.PlotSettings.Data(:,2) = [NaN 0 6.5 3 7.0 NaN NaN]; % offsets
        handles.PlotToggles.Data(:,1) = logical([0 1 0 1 1 1 0]);
        
        % Rewards
        handles.watercoeffs = [0.0009982 0.1313 0.3161]; % water per drop
        
        % HomeSensor type
        handles.fliphome = 1;
        
        % visual version
        handles.VisualVersion.Value = 0;
        handles.VisualAirTrials.Visible = 'off';
        handles.VisualOnlyTrials.Visible = 'off';
        
        % Photometry 
        handles.Photometry.Value = 0;
        handles.PhotometryParams.Data = [5000 211 531 0.6 0.6];
        
    case {'BALTHAZAR'} % Rig 2
        
        handles.TrialSettings.Data = [500 500 500 100 400 500]';
        
        handles.useserver = 1; % change to zero if there's a network issue
        
        % sensors and scaling
        handles.DAC_settings.Data = [2.0 2.15]';
        
        % Plots
        handles.PlotSettings.Data(:,1) = [NaN 1 0.5 2 0.2 NaN NaN]; % gains
        handles.PlotSettings.Data(:,2) = [NaN 0 6.5 3 7.0 NaN NaN]; % offsets
        handles.PlotToggles.Data(:,1) = logical([0 1 0 1 1 1 0]);
        
        % Rewards
        handles.watercoeffs = [0.001357 0.08917 0.4286]; % water per drop
        
        % HomeSensor type
        handles.fliphome = 1;
        
        % visual version
        handles.VisualVersion.Value = 0;
        handles.VisualAirTrials.Visible = 'off';
        handles.VisualOnlyTrials.Visible = 'off';
        
        % Photometry 
        handles.Photometry.Value = 0;
        handles.PhotometryParams.Data = [5000 211 531 0.6 0.6];
        
    case {'PRIYANKA-HP'}
        handles.useserver = 1; % change to zero if there's a network issue
        
        % sensors and scaling
        handles.DAC_settings.Data = [2.0 2.5]';
        
        % Plots
        handles.PlotSettings.Data(:,1) = [NaN 1 0.5 2 0.2 NaN NaN]; % gains
        handles.PlotSettings.Data(:,2) = [NaN 0 6.0 6 5 NaN NaN]; % offsets
        handles.PlotToggles.Data(:,1) = logical([0 1 1 1 1 1 1]);
        
        % Rewards
        handles.watercoeffs = [0.0006286 0.09254 0.918]; % water per drop
        
        % HomeSensor type
        handles.fliphome = 0;
        
        % Photometry 
        handles.Photometry.Value = 0;
        handles.PhotometryParams.Data = [5000 211 531 0.6 0.6];

end
end