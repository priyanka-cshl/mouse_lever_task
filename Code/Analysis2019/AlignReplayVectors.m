

function [new_vec] = AlignReplayVectors(xdata,ydata)

%% =============================================================
% no. of iterations for minsearch and func handles
%% =============================================================
Eval_max = 100;
Iter_max = 100;
model_fit = @MatchVecs;
start_vec = 1.006; 

%% =============================================================
%% original and replayed traces
%% =============================================================

% xdata = Replay.CloseLoopTraces{1}(:,3);
% ydata = Replay.ReplayTraces{1,1}(:,3);

% make vectors the same size
x = min(length(xdata),length(ydata));
xdata(x:end,:) = [];
ydata(x:end,:) = [];

%% Call fminsearch to begin with the start_vec as the lag and scaling fac
options = optimset('MaxFunEvals',Eval_max,'MaxIter',Iter_max);
new_vec = lsqcurvefit(model_fit,start_vec,ydata,xdata,0.9,1.1,options);

    function [zdata] = MatchVecs(start_vec,ydata)
        
        zdata = interp1(start_vec(1)*(1:length(ydata)),ydata,1:length(ydata));
        zdata = zdata';
    end

end


