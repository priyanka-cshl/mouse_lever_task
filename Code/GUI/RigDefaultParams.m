function [handles] = RigDefaultParams(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>

% common to all Rigs
% Run by default in Behavior Acquisition Mode
handles.PIDMode.Value = 0; % acquire PID (or other external analog signals on ai13) instead of Lick Piezo (ai12)

% files and paths
handles.file_names.Data(2) = {'C:\Data\Behavior'};
handles.file_names.Data(3) = {'\\grid-hs\albeanu_nlsas_norepl_data\pgupta\Behavior'};

% Rates
handles.DAQrates.Data = [500 20]';

% default params
handles.TrialSettings.Data = [4.8 0.2 200 100 5000 500]'; % trial highlim, trial lowlim, ~ , trialmin, trialmax, ITI
handles.adaptive_holds.Value = 1;
handles.Odor_list.Value = 1 + [0 1 2 3]'; % active odors
handles.odor_priors.Value = 0;
handles.which_perturbation.Value = 1; % no perturbations
handles.openloop = 0; % Run in close-loop mode
handles.AdaptiveTrigger.Value = 1;
handles.OdorSequence.Value = 1;
handles.OpenLoopSettings.Value = 1; % normal close loop mode

% start by default in normal close loop mode
handles.OpenLoopSettings.Value = 1;
handles.ReplayState.String = 'Close loop';
handles.OpenLoopProgress.Data(:,1) = [NaN 0 0 0]';
handles.OpenLoopProgress.Data(:,2) = [0 0 0 0];

% Target zones
handles.ZoneLimitSettings.Data(1) = 0.3; % zone width
handles.minimumtarget = 1;
handles.all_targets = flipud([1:0.25:3.75]');
handles.TargetsActive.Data = 1 + 0*handles.TargetsActive.Data;
handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
handles.PseudoRandomZones.Value = 1;

% Transfer function
handles.calibrate_transfer_function.Enable = 'off'; % disable transfer function calibrator
handles.locations_per_zone.Data = [20 0 60]'; % TF - locations per zone
handles.TFtype.Value = 1; % 1 = fix speed, 0 = fixed start
handles.TFtype.Enable = 'on';
handles.TFgain.Data = 1;

% manifold and motor
handles.MotorLocations = 115; % currently used for variable gain
handles.MotorLocationArduinoMax = 120;
handles.MotorLocationsFixSpeed = 100; % for fix speed
handles.ManifoldOutlets = 24; % 32 in total - out of which only 24 are used
handles.motor_params = 4; % motor step size
handles.PerturbationSettings.Data(3) = 30;
handles.myoffset.Data(1) = 30;

% currently unused settings
handles.MFC_table.Data = [1.6 0.64]'; %[1.6 0.4]';
handles.Zero_MFC.Value = 0;
handles.which_stage.Value = 3; % training stage
handles.TransferFunction.Data(2) = 100; % block size (1 = no blocks)
handles.blockshiftfactor.Data(1) = 2;

% hacks - for recreating a specific session
handles.trialsequence = [8 11 5 10 3];% 8 4 1 6 2 8 2 11 2 11 3 8 4 7 1];
handles.holdtimes = [310 262 239 203 350];

switch char(handles.computername)
    
    case {'PRIYANKA-HP'} % Rig1
        
        handles.useserver = 1; % change to zero if there's a network issue
        
        % sensors and scaling
        handles.DAC_settings.Data = [2.0 2.5]'; % Lever scaling
        
        % Plots
        handles.PlotSettings.Data(:,1) = [NaN 1 0.5 2 0.2 NaN NaN]; % gains
        handles.PlotSettings.Data(:,2) = [NaN 0 6.0 6 5 NaN NaN]; % offsets
        handles.PlotToggles.Data(:,1) = logical([0 1 1 1 1 1 1]);
        
        % Rewards
        handles.watercoeffs = [0.001738 0.04964 1.275]; % water per drop [0.0006286 0.09254 0.918];
        handles.RewardControls.Data = [35 5 50 100 100]'; % reward: time-I, time-II, IRI, hold-II, trial-off-lag
        handles.MultiRewards.Value = 1;
        
        % HomeSensor type
        handles.fliphome = 0;
        
        % visual trials
        handles.VisualAirTrials.Value = 0;
        handles.VisualOnlyTrials.Value = 0;
        
        % Photometry 
        handles.Photometry.Value = 0;
        handles.PhotometryParams.Data = [5000 211 531];
        
    case {'JUSTINE'} % Rig2
        
        handles.useserver = 1; % change to zero if there's a network issue
        
        % sensors and scaling
        handles.DAC_settings.Data = [2.0 2.15]';
        
        % Plots
        handles.PlotSettings.Data(:,1) = [NaN 1 0.5 2 0.1 NaN NaN]; % gains
        handles.PlotSettings.Data(:,2) = [NaN 0 6.5 3 7.0 NaN NaN]; % gains
        handles.PlotToggles.Data(:,1) = logical([0 1 1 1 1 1 1]);
        
        % Rewards
        handles.watercoeffs = [0.0006286 0.09254 0.918]; % water per drop
        handles.RewardControls.Data = [35 5 50 100 200]'; % reward: time-I, time-II, IRI, hold-II, trial-off-lag
        handles.MultiRewards.Value = 1;
        
        % HomeSensor type
        handles.fliphome = 1;
        
        % Photometry 
        handles.Photometry.Value = 1;
        handles.PhotometryParams.Data = [5000 211 531];
end
end