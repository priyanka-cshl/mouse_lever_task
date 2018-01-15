function [handles] = MouseDefaults(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>
switch char(handles.file_names.Data(1))
    case ('PM32')
        handles.all_targets = [1.0:0.25:3.75]';
    case ('PM34')
        handles.all_targets = [1.0:0.25:3.25]';
    case ('PM35')
        handles.all_targets = [1.0:0.25:3.25]';
    case ('PM36')
        handles.all_targets = [1.0:0.25:3.25]';
end

handles.targets_to_use = [1 1 1];
handles.TargetLevel1Active.Value = 1;
handles.TargetLevel2Active.Value = 1;
handles.TargetLevel3Active.Value = 1;
handles.target_level_array.Data = handles.all_targets(ismember(floor(handles.all_targets),find(handles.targets_to_use)));
handles.ZoneLimitSettings.Data(2) = max(handles.target_level_array.Data);
handles.ZoneLimitSettings.Data(3) = min(handles.target_level_array.Data);
end