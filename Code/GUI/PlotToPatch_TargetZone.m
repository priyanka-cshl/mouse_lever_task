function [handle_in] = PlotToPatch_TargetZone(handle_in, data_in, timestamp_in)
% data_in must be a column vector
a = data_in(:,1)'; b = data_in(:,2)';
f = find(diff(a)~=0);
f = sort([1 length(a) f (f+1)]);
f = f';
X = [timestamp_in(f)' fliplr(timestamp_in(f)')];
Y = [a(f) fliplr(b(f))];
handle_in.Faces = 1:length(X);
handle_in.Vertices = [X' Y'];
end