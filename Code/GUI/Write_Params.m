function Write_Params(h)
%% pull all params
[~, params1, not_ints1] = Current_Settings(h,0);
[~, params2, not_ints2] = Current_Settings(h,1);

%% if acquisition is Running and params were sent - update settings file
if get(h.startAcquisition,'value')
    % replace last three values in params1 to store Stay Time min and Stay
    % Time Max
    params1(1) = h.ZoneLimitSettings.Data(1); % MinWidth
    %params1(2) = h.ZoneLimitSettings.Data(2); % PropWidth
    params1(2) = h.RewardControls.Data(2); % IRI - when multirewards is off
    params1(end-4) = h.MultiRewards.Value*h.RewardControls.Data(2); % IRI
    params1(end-2) = h.TargetHold.Data(1); % StayMean
    params1(end-1) = h.TargetHold.Data(2); % StayMin
    params1(end) = h.TargetHold.Data(3); % StayMax
    params2(1) = h.trigger_ext_camera.Value; % camera on or not
    fwrite(h.settingsfileID,[-1*h.timestamp.Data params1 params2],'double');
end