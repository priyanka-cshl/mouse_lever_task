function [OpenLoop] = ParseReplayTrials(Traces, TrialInfo, TTLs, ReplayTTLs)

%% globals
global SampleRate; % = 500; % samples/second
global startoffset; % = 1; % seconds
traceOverlap = SampleRate*startoffset;
AllTargets = 1:0.25:3.75; % for assigning target zone values

% How many open loop templates are there?
% typically only 1 - in rare cases there might be two
TemplateTrials(:,1) = find(diff(strcmp(TrialInfo.Perturbation,'OL-Template'))== 1) + 1;
TemplateTrials(:,2) = find(diff(strcmp(TrialInfo.Perturbation,'OL-Template'))==-1);

% for each template - get a concatenated trace for
% Lever, Motor, Resp, Licks, TrialON, Rewards, TargetZone, Timestamps (?)
whichTraces = fieldnames(Traces);
for i = 1:size(TemplateTrials,1) % no. of templates
    
    %% Open Loop Template
    
    whichTrials = TemplateTrials(i,1):TemplateTrials(i,2);
    OpenLoop.TemplateTraces.TrialIDs{i} = whichTrials;
    for j = 1:size(whichTraces,1)
        temp = cellfun(@(x) ...
            x(1:end-traceOverlap), Traces.(whichTraces{j})(whichTrials), ...
            'UniformOutput', false);
        
        % add in the overlap for the very last trial
        OpenLoop.TemplateTraces.(whichTraces{j})(i) = {[cell2mat(temp(:)); ...
            Traces.(whichTraces{j}){whichTrials(end)}(end-traceOverlap+1:end,1)]};
    end
    % use the TrialON column
    % 1. to construct the targetzone trace - for plotting
    % 2. to include OdorON periods (in -ve)
    TrialTrace = cell2mat(OpenLoop.TemplateTraces.Trial(i));
    % make sure any trial ON periods preceding trial1 start are ignored
    TrialTrace(1:traceOverlap,1) = 0;
    % get trial ON-OFF indices
    Idx = [find(diff(TrialTrace>0)==1)+1 find(diff(TrialTrace>0)==-1)];
    % get OdorStart Times w.r.t. Trial start (from the behavior file)
    Idx(:,3) = Idx(:,1) + ceil(SampleRate*TrialInfo.OdorStart(whichTrials,2));
    if ~isempty(TTLs)
        % OdorStart Times can also be extracted from OEPS TTLs
        Idx(:,4) = Idx(:,1) + ceil(SampleRate*TTLs.Trial(whichTrials,4));
        if any(abs(Idx(:,3)-Idx(:,4))>5)
            disp('mismatch in OdorOn Timestamps between behavior and OEPS files');
            keyboard;
        end
    end
    temp = 0*TrialTrace;
    x1 = 1;
    for k = 1:size(Idx,1)
        % TargetZone vector
        x2 = Idx(k,2);
        temp(x1:x2,1) = AllTargets(TrialInfo.TargetZoneType(whichTrials(k)));
        x1 = x2 + 1;
        
        % OdorON + TrialON vector
        TrialTrace(Idx(k,3):Idx(k,1)-1,1) = -TrialTrace(Idx(k,1));
    end
    OpenLoop.TemplateTraces.TargetZone(i) = {temp};
    OpenLoop.TemplateTraces.Trial(i) = {TrialTrace};
    
    Rewards_TS(:,1) = find(diff(OpenLoop.TemplateTraces.Rewards{i})==1)+1;
    
    %% Replay traces
    
    whichTrials = find(strcmp(TrialInfo.Perturbation,'OL-Replay'));
    whichTrials(whichTrials<TemplateTrials(i,2)) = []; % only relevant if there's more than one openloop template
    if i < size(TemplateTrials,1) % more than one open loop template (no more than two though
        whichTrials(whichTrials>TemplateTrials(i+1,2)) = [];
    end
    
    OpenLoop.ReplayTraces.TrialIDs{i} = whichTrials;
    
    for r = 1:numel(whichTrials)
        % the replay trace is laready concatenated - but needs to be split
        % into trials - because a few samples get missed during Arduino
        % updates at the end of every OL - template trial;
        X = [];
        if isempty(ReplayTTLs) % Use the behavior trace itself
            % find reward timestamps for the replayed trace
            % use reward TS to align the template and replayed traces
            Rewards_TS(:,1+r) = find(diff(Traces.Rewards{whichTrials(r)})==1)+1;
            X(:,[2 4]) = [Rewards_TS(:,1) Rewards_TS(:,1+r)];
        else % use the OdorOFF TTLs from OEPS
            % find trialOFF timestamps for the replayed trace using OEPS
            % use these T-OFF TS to align the template and replayed traces
            X(:,2) = Idx(:,2); % Trial OFF indices from the template behavior trace
            % which set of ReplayTTLs to use
            f = find(ReplayTTLs.TrialID==whichTrials(r));
            T_off = ReplayTTLs.OdorValve{f}(:,2);
            % sometimes there is 1 extra odor transition at trialstart
            % if replay trial starts with a different odor - delete that
            while size(T_off,1)>size(X,1)
                T_off(1,:) = [];
            end
            % account for the padded startoffset samples in the template
            X(:,4) = ceil((T_off+startoffset)*SampleRate);
        end
        % col 2 and col 4 now contain stop indices for each trial segment
        % col 2 - w.r.t. template, col 4 - w.r.t. replayed trace
        % get start indices for both segments
        X(:,[1 3]) = [[1 1]; 1+X(1:end-1,[2 4])];
        % get segment lenths
        X(:,5) = X(:,2) - X(:,1);
        X(:,6) = X(:,4) - X(:,3);
        % sometimes the first segmenmt has a few extra samples
        if (X(1,6)-X(1,5))>0
            X(1,3) = X(1,3) + X(1,6) - X(1,5);
        end
        % get the count of missing samples - difference in segment lengths
        X(:,7) = (X(:,4) - X(:,3)) - (X(:,2) - X(:,1));
        
        % 2. extract the actual replayed trace
        for j = 1:size(whichTraces,1)
            temptrace = Traces.(whichTraces{j}){whichTrials(r)};
            for k = 1:size(X,1) % for every reward
                snippet = vertcat(NaN*ones(abs(X(k,7)),1),temptrace(X(k,3):X(k,4)));
                patchedtrace(X(k,1):X(k,2),1) = snippet;
            end
            OpenLoop.ReplayTraces.(whichTraces{j}){i}(:,r) = patchedtrace;
        end
        
    end
    
    %% sanity checks
    Residuals = OpenLoop.ReplayTraces.Motor{i} - ...
        OpenLoop.TemplateTraces.Motor{i}(1:size(OpenLoop.ReplayTraces.Motor{i},1),1);
    % ignore residuals before first trial start
    Residuals(1:(SampleRate*startoffset),:) = 0;
    
    ErrorDist = fitdist(Residuals(:),'normal');
    % check if mean is ~0 and if sigma is very small (<5)
    if ~round(ErrorDist.mean,1) && ErrorDist.sigma<5
        disp('template and replay traces align well');
    else
        disp('template and replay traces do not seem to align well');
        keyboard;
    end
    
end