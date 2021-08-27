function [handles] = LoadWheelSettings(handles)
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
Allfiles = dir([fullfile(foldername_local,animal_name),filesep,'*.mat']);
handles.trainingday.String = ['Training day ',num2str(...
    size(dir([fullfile(foldername_local,animal_name),filesep,'*r0*']),1))];

if ~isempty(Allfiles)  
    X = load(fullfile(foldername_local,animal_name,Allfiles(end).name));
    if size(X.session_data.legends_trial,2)==31
        % load settings
        handles.TargetHold.Data = X.session_data.params(end,13:15)';
        handles.locations_per_zone.Data = X.session_data.params(end,21:23)';
        handles.RewardControls.Data(1) = X.session_data.params(end,7);
        handles.ZoneLimitSettings.Data(1) = X.session_data.params(end,2);
        if isfield(X.session_data, 'ForNextSession')
        	handles.RewardControls.Data(3) = X.session_data.ForNextSession(1);
            handles.TFLeftprobability.Data(1) = X.session_data.ForNextSession(2);
        end
        if strcmp(X.session_data.legends_trial(11),'IRI')
            handles.RewardControls.Data(2) = X.session_data.params(end,11);
            handles.MultiRewards.Value = (X.session_data.params(end,11)>0);
        end
        if strcmp(X.session_data.legends_trial(11),'MultirewardIRI')
            handles.MultiRewards.Value = (X.session_data.params(end,11)>0);  
            if handles.MultiRewards.Value
                handles.RewardControls.Data(2) = X.session_data.params(end,11);
            else
                handles.RewardControls.Data(2) = X.session_data.params(end,3);
            end
        end
    end
end
end