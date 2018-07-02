function [handles] = MouseDefaults(handles)
switch char(handles.file_names.Data(1))
    case ('PM32')
        %handles.all_targets = [1.0:0.25:3.75]';
        handles.TargetsActive.Data = [1 1 1 1 1 1 1 1 1 1 1 1];
    case ('PM34')
        %handles.all_targets = [1.0:0.25:3.75]';
        handles.TargetsActive.Data = [1 1 1 1 1 1 1 1 1 1 1 1];
    case ('PM35')
        %handles.all_targets = [1.0:0.25:3.25]';
        handles.TargetsActive.Data = [1 1 1 1 1 1 1 1 1 1 0 0];
    case ('PM36')
        %handles.all_targets = [1.0:0.25:3.25]';
        handles.TargetsActive.Data = [1 1 1 1 1 1 1 1 1 1 0 0];
end
end