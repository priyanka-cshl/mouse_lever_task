function [handles] = RigDefaults(handles)
% rig specific settings
handles.computername = textread('hostname.txt','%s'); %#ok<*DTXTRD>
switch char(handles.computername)
    case 'marbprec'
        handles.file_names.Data(2) = {'C:\Data\Behavior'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\Behavior'};
        handles.NIchannels = 11;
        handles.DAC_settings.Data = [1.6 1.85]';
        % motor location settings
        handles.motor_params = 4;
        % disable transfer function calibrator
        handles.calibrate_transfer_function.Enable = 'off';
        % MFC settings
        handles.MFC_table.Data = [1.55 0.4]';
        % training stage
        handles.which_stage.Value = 3;
        % TF - locations per zone
        handles.locations_per_zone.Data = [20 0 60]';
        % Trial settings
        handles.TrialSettings.Data = [4.8 0.2 200 0 100 2000]';
        % zone width
        handles.ZoneLimitSettings.Data = [0.5 0.1]';
        % reward settings
        handles.RewardControls.Data = [40 200 50 5]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        handles.target_level_array.Data = [1.5 2.5 3.5]';
        % shrink target zone
        handles.ShrinkTargetLocations.Value = 1;
        
        
    case 'PRIYANKA-PC'
        handles.file_names.Data(2) = {'C:\Data\Behavior'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\Behavior'};
        handles.NIchannels = 11;
        handles.DAC_settings.Data = [2.2 0.7]';
        % motor location settings
        handles.motor_params = 4;
        handles.TrialSettings.Data(2) = 0.5;
        % disable transfer function calibrator
        handles.calibrate_transfer_function.Enable = 'off';
        % MFC settings
        handles.MFC_table.Data = [1.55 0.4]';
        % training stage
        handles.which_stage.Value = 3;
        % TF - locations per zone
        handles.locations_per_zone.Data = [50 0 50]'; % [20 0 80]'
        % Trial settings
        handles.TrialSettings.Data = [4.5 0.2 100 20 600 2000]';
        % zone width
        handles.ZoneLimitSettings.Data = [0.4 0.1]';
        % reward settings
        handles.RewardControls.Data = 30;
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
end
end