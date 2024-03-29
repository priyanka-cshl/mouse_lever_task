function Params2File(h)
%% pull all params
[~, params] = GetSettings4Arduino(h);

%% if acquisition is Running and params were sent - update settings file
if get(h.startAcquisition,'value')
    % replace last three values in params1 to store Stay Time min and Stay
    % Time Max
%     params1(1) = h.ZoneLimitSettings.Data(1); % MinWidth
%     %params1(2) = h.ZoneLimitSettings.Data(2); % PropWidth
%     params1(2) = h.RewardControls.Data(2); % IRI - when multirewards is off
%     params1(end-4) = h.MultiRewards.Value*h.RewardControls.Data(2); % IRI
%     params1(end-2) = h.TargetHold.Data(2); % StayMean
%     params1(end-1) = h.TargetHold.Data(1); % StayMin
%     params1(end) = h.TargetHold.Data(3); % StayMax
%     params2(1) = h.trigger_ext_camera.Value; % camera on or not
    fwrite(h.settingsfileID,[-1*h.timestamp.Data params],'double');
end