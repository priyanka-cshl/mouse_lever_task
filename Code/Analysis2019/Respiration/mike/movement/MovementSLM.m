function [pks,locs,w,p,vel,acc] = MovementSLM(lever_smooth)

x = 1:length(lever_smooth);

prescription = slmset('order', 2, 'interiorknots', 'free', 'knots', 80); % piecewise linear
slm = slmengine(x,lever_smooth,prescription); % create model
fitLine = slmeval(x,slm); % evaluate model

vel = gradient(fitLine);
acc = gradient(vel);

threshold = 0.005;

[pks,locs,w,p] = findpeaks(abs(acc), 'MinPeakHeight', threshold, 'MinPeakDistance', 10);

end