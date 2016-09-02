function [handles] = handles_to_params(handles);
handles.param_array(1:2) = str2double(handles.Lever_rescale.String);
% handles.param_array(3:5) = str2double(handles.target_definition.String);
% handles.param_array(6) = str2double(handles.decouple_reward_and_stimulus.String);
% handles.param_array(7:9) = str2double(handles.fake_target_definition.String);
% handles.param_array(10) = str2double(handles.delay_feedback_by.String);
% handles.param_array(11) = str2double(handles.IsDistractorON.String);
% handles.param_array(12) = str2double(handles.delay_distractor_by.String);
handles.param_array(13) = str2double(handles.reward_duration.String);
end
