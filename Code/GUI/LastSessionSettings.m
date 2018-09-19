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
            %handles.DAC_settings.Data = X.session_data.ForNextSession(1:2)';
        end
        if any(strcmp(X.session_data.ForNextSession_Legends,'TriggerHoldMin'))
            handles.TriggerHold.Data = X.session_data.ForNextSession(3:5)';
        end
        if any(strcmp(X.session_data.ForNextSession_Legends,'TargetHoldMean'))
            last_session_median = round(X.session_data.ForNextSession(find(strcmp(X.session_data.ForNextSession_Legends,'TargetHoldMean'))));
            if last_session_median < 25
                handles.TargetHold.Data(2) = 25;
                handles.TargetHold.Data(1) = 0;
            elseif last_session_median >= 300
                %handles.TargetHold.Data(2) = 300;
                handles.TargetHold.Data(2) = last_session_median;
                handles.TargetHold.Data(1) = max([250 last_session_median-50]);
                handles.AntiBias.Value = 1;
                %handles.TargetHold.Data(3) = 400;
                %handles.adaptive_holds.Value = 0;
            else
                handles.TargetHold.Data(2) = last_session_median;
                handles.TargetHold.Data(1) = handles.TargetHold.Data(2) - 25;
            end
            
        end
        if any(strcmp(X.session_data.ForNextSession_Legends,'RewardHold-I'))
            handles.RewardControls.Data(1) = X.session_data.ForNextSession(end-2);
            handles.TFLeftprobability.Data(1) = X.session_data.ForNextSession(end-1);
            handles.summedholdfactor.Data = X.session_data.ForNextSession(end);
        end
    end
end
end