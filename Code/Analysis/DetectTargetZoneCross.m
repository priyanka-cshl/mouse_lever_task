function [MyTraces] = DetectTargetZoneCross(trace,threshold)

global timewindow;

X = trace; 
X(X>=threshold)=threshold; 
X(X<threshold)=0;

MyTraces = [];
% find time of threshold crossing
t = find(diff(X)<0);
t_out = find(diff(X)<0);
t_stay = [];
if ~isempty(t)
    for i = 1:numel(t)
        if ~isempty(find(t_out>t(i)))
            t_stay(i) = t_out(find(t_out>t(i),1)) - t(i);
        else
            t_stay(i) = NaN;
        end
    end
    [~, j] = max(t_stay);
    MyTraces = [MyTraces; trace( t(j)-timewindow : t(j)+timewindow )];
end
end