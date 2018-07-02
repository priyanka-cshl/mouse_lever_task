function [handles] = RigDefaultParams(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>
switch char(handles.computername)
    case {'marbprec', 'PRIYANKA-HP'}
        handles.file_names.Data(2) = {'C:\Data\Behavior'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\Behavior'};
        handles.ManifoldOutlets = 16;
        handles.DAC_settings.Data = [2.2 0.5]';
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
        handles.RewardControls.Data = [25 100 50 5]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        %handles.target_level_array.Data = [1:0.25:3.75]'; %[3:0.25:3.75]';
        handles.all_targets = [1:0.25:3.75]';
        handles.TargetsActive.Data = 1 + 0*handles.TargetsActive.Data;
        handles.target_level_array.Data = handles.all_targets(find(handles.TargetsActive.Data));
        handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
        handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
        % shrink target zone
        handles.ShrinkTargetLocations.Value = 1;
        handles.MotorLocations = 100;
        handles.MotorLocationArduinoMax = 120;
        handles.minimumtarget = 1;
        handles.MotorLocationsRange = 140; %165; %165;
        handles.watercoeffs = [0.009211 -0.0299]; % water per drop = coeef(1)*time +coeef(2)
        handles.fliphome = 0; 
        handles.TFtype = 0; % 1 = fix speed, 0 = fixed start
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
        handles.RewardControls.Data = [25 100 50 5]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        %handles.target_level_array.Data = [1:0.25:3.75]'; %[3:0.25:3.75]';
        handles.all_targets = [1:0.25:3.75]';
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