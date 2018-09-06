function [handles] = RigDefaultParams(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>
switch char(handles.computername)
    case {'marbprec', 'PRIYANKA-HP'}
        % files and paths
        handles.file_names.Data(2) = {'C:\Data\Behavior'};
        handles.file_names.Data(3) = {'\\grid-hs\albeanu_nlsas_norepl_data\pgupta\Behavior'};
        
        % Rates
        handles.DAQrates.Data = [500 20]';
        
        % sensors and scaling
        handles.DAC_settings.Data = [1.85 2.3]';
        handles.RS_scaling.Data = [-1 5.5]';
        handles.watercoeffs = [0.00134 0.0515 0.099]; % water per drop
        handles.fliphome = 0; 
        
        % default params
        handles.TrialSettings.Data = [4.8 0.2 200 100 5000 5000]'; % trial highlim, trial lowlim, ~ , trialmin, trialmax, ITI
        handles.RewardControls.Data = [35 5 50 100 100]'; % reward: time-I, time-II, IRI, hold-II, trial-off-lag
        handles.MultiRewards.Value = 1;
        handles.adaptive_holds.Value = 1;
        handles.Odor_list.Value = 1 + [1 2 3]'; % active odors
        handles.which_perturbation.Value = 1; % no perturbations
        handles.openloop = 0; % Run in close-loop mode
        
        % Target zones
        handles.ZoneLimitSettings.Data(1) = 0.3; % zone width
        handles.minimumtarget = 1;
        handles.all_targets = flipud([1:0.25:3.75]');
        handles.TargetsActive.Data = 1 + 0*handles.TargetsActive.Data;
        handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
        handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
        handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
        
        % Transfer function
        handles.calibrate_transfer_function.Enable = 'off'; % disable transfer function calibrator
        handles.locations_per_zone.Data = [20 0 60]'; % TF - locations per zone
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
        handles.TransferFunction.Data(2) = 1; % block size (1 = no blocks)
        
        % hacks - for recreating a specific session
        handles.trialsequence = [8 11 5 10 3];% 8 4 1 6 2 8 2 11 2 11 3 8 4 7 1];
        handles.holdtimes = [310 262 239 203 350];
       
    case {'PRIYANKA-PC','DESKTOP-05QAM9D'}
        handles.file_names.Data(2) = {'C:\Data\Behavior'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\Behavior'};
        %handles.NIchannels = 11;
        handles.ManifoldOutlets = 16;
        handles.DAC_settings.Data = [2.8 0.65]';
        handles.RS_scaling.Data = [-1 5.5]';
        % motor location settings
        handles.motor_params = 4;
        % disable transfer function calibrator
        handles.calibrate_transfer_function.Enable = 'off';
        % MFC settings
        handles.MFC_table.Data = [1.6 0.64]'; %[1.6 0.4]';
        % training stage
        handles.which_stage.Value = 3;
        % TF - locations per zone
        handles.locations_per_zone.Data = [20 0 60]';
        % Trial settings
        handles.TrialSettings.Data = [4.8 0.2 200 100 3500 5000]';
        % zone width
        handles.ZoneLimitSettings.Data(1) = 0.4;%[0.5 0.1]';
        % reward settings
        handles.RewardControls.Data = [25 5 50 100 100]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        %handles.target_level_array.Data = [1:0.25:3.75]'; %[3:0.25:3.75]';
        handles.all_targets = flipud([1:0.25:3.75]');
        handles.TargetsActive.Data = 1 + 0*handles.TargetsActive.Data;
        handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
        handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
        handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
        % shrink target zone
        handles.ShrinkTargetLocations.Value = 1;
        handles.MotorLocations = 100;
        handles.MotorLocationArduinoMax = 120;
        handles.minimumtarget = 1;
        handles.MotorLocationsRange = 140;
        handles.watercoeffs = [0.01051 -0.1061]; % water per drop = coeef(1)*time +coeef(2)
        handles.fliphome = 1;        
        handles.TFtype = 0; % 1 = fix speed, 0 = fixed start
end
end