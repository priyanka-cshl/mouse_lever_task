function [handles] = LastSessionSettings(handles)
animal_name = char(handles.file_names.Data(1));
foldername_local = char(handles.file_names.Data(2));
Allfiles = dir([fullfile(foldername_local,animal_name),filesep,'*.mat']);
handles.trainingday.String = ['Training day ',num2str(...
    size(dir([fullfile(foldername_local,animal_name),filesep,'*r0*']),1))];

if ~isempty(Allfiles)  
    X = load(fullfile(foldername_local,animal_name,Allfiles(end).name));
    if isfield(X.session_data, 'ForNextSession')
        if any(strcmp(X.session_data.ForNextSession_Legends,'DAQGain'))
            handles.DAC_settings.Data = X.session_data.ForNextSession(1:2)';
        end
        if any(strcmp(X.session_data.ForNextSession_Legends,'TriggerHoldMin'))
            handles.TriggerHold.Data = X.session_data.ForNextSession(3:5)';
        end
        if any(strcmp(X.session_data.ForNextSession_Legends,'TargetHoldMean'))
            handles.TargetHold.Data(2) = ...
            round(X.session_data.ForNextSession(find(strcmp(X.session_data.ForNextSession_Legends,'TargetHoldMean'))));
            handles.TargetHold.Data(1) = handles.TargetHold.Data(2) - 25;
        end
        if any(strcmp(X.session_data.ForNextSession_Legends,'RewardHold-I'))
            handles.RewardControls.Data(1) = X.session_data.ForNextSession(end-2);
            handles.TFLeftprobability.Data(1) = X.session_data.ForNextSession(end-1);
            handles.summedholdfactor.Data = X.session_data.ForNextSession(end);
        end
    end
end
end