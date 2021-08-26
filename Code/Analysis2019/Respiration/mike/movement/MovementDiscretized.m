function [pks,locs,w,p,vel,acc] = MovementDiscretized(lever_smooth)

step = 0.2;

edges = -1:step:6;
lever_bins = discretize(lever_smooth,edges);

lever_discretized = lever_bins*step - 1 - 0.5*step;

velocity = diff(lever_discretized);
velocity_peaks = find(velocity ~= 0);

velocity_smooth = zeros(1, length(lever_smooth));
for i = 1:length(velocity_peaks)-1
    velocity_smooth(velocity_peaks(i):velocity_peaks(i+1)-1) = velocity(velocity_peaks(i))/(velocity_peaks(i+1)-velocity_peaks(i));
end

acc = gradient(velocity_smooth);
vel = velocity_smooth;

[pks,locs,w,p] = findpeaks(abs(acc), 'MinPeakHeight', 0.005, 'MinPeakDistance', 10);

end