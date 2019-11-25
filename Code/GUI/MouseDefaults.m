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
    case ('J1')
        handles.odor_sequence.Data = [1 2 3]; 
    case ('J2')
        handles.odor_sequence.Data = [3 1 2];
    case ('J3')
        handles.odor_sequence.Data = [3 2 1];
    case ('J4')
        handles.odor_sequence.Data = [2 1 3];
    case ('J5')
        handles.odor_sequence.Data = [2 3 1];
    otherwise
        handles.odor_sequence.Data = [1 2 3];
end
end