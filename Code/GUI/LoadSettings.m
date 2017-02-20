function [handles] = LoadSettings(handles)
    animal_name = char(handles.file_names.Data(1));
    foldername_local = char(handles.file_names.Data(2));
    Allfiles = dir(fullfile(foldername_local,animal_name));
    X = load(fullfile(foldername_local,animal_name,Allfiles(end).name));
    
    if size(X.session_data.legends_trial,2)==31
        % load settings
        handles.TargetHold.Data = X.session_data.params(end,13:15)';
        handles.locations_per_zone.Data = X.session_data.params(end,21:23)';
        handles.RewardControls.Data(1) = X.session_data.params(end,7);    
        handles.ZoneLimitSettings.Data = X.session_data.params(end,2:3)';
        handles.TrialSettings.Data(3) = X.session_data.params(end,12);
        if strcmp(X.session_data.legends_trial(11),'IRI')
            handles.RewardControls.Data(2) = X.session_data.params(end,11);
            handles.MultiRewards.Value = (X.session_data.params(end,11)>0);
        end
    end
end