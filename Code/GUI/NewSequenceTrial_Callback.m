function NewSequenceTrial_Callback(h)

% home motor if needed
if h.motor_home.BackgroundColor(1) == 0.5
    h.Arduino.write(72,'uint16');
end

disp(['---------- New SequenceTrial (#', num2str(h.current_trial_block.Data(2)),') ----------']);
%h.current_trial_block.Data(3) = no. of trials per repeat
h.current_trial_block.Data(4) = 1 + mod((h.current_trial_block.Data(2)-1),h.current_trial_block.Data(3)); % which trial
h.current_trial_block.Data(5) = ceil(h.current_trial_block.Data(2)/h.current_trial_block.Data(3));% which repeat
h.current_trial_block.Data(6) = h.TrialSequence(h.current_trial_block.Data(2),2); % which odor in spot 5
h.current_trial_block.Data(7) = h.TrialSequence(h.current_trial_block.Data(2),1); % which location

%% invoke target definition callback (this automatically calls Update_Params)
set(h.motor_home,'BackgroundColor',[0.94 0.94 0.94]);
guidata(h.hObject, h);
OpenLoopOdorLocator('Update_Callback',h.hObject,[],h);

