function [handle_in] = PlotToPatch(handle_in, data_in, timestamp_in, offsets, whichcase)
if nargin<5
    whichcase = 0;
end
% data_in must be a column vector
on_indices = timestamp_in( find(diff(data_in)==1) +1 );
off_indices = timestamp_in( find(diff(data_in)==-1) +1 );
if any(on_indices)
    ts_on_Y = [ones(length(on_indices)*2,1);zeros(length(off_indices)*2,1)];
    [ts_on_X,sortId] = sort([on_indices;on_indices;off_indices;off_indices]);
    ts_on_Y = ts_on_Y(sortId);
    if (ts_on_Y(end) == 1 || whichcase)
        ts_on_X = [0; ts_on_X; timestamp_in(end); timestamp_in(end); 0];
        ts_on_Y = [abs(ts_on_Y(1)-1); abs(ts_on_Y(1)-1); ts_on_Y; 0; 0]*diff(offsets);
        ts_on_Y = ts_on_Y + offsets(1);
        handle_in.Vertices = [ts_on_X ts_on_Y];
        handle_in.Faces = 1:length(ts_on_X);
    end
end
end