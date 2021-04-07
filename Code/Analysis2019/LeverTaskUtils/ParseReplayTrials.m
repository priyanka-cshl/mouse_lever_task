function [Replay, TTLs] = ParseReplayTrials(MyData, MySettings, DataTags, TrialInfo, TTLs)

%% globals
global SampleRate; % = 500; % samples/second
global startoffset; % = 1; % seconds

%% Get Column IDs

LeverCol = find(cellfun(@isempty,regexp(DataTags,'Lever'))==0);
MotorCol = find(cellfun(@isempty,regexp(DataTags,'Motor'))==0);
EncoderCol = find(cellfun(@isempty,regexp(DataTags,'Encoder'))==0);
if ~isempty(find(cellfun(@isempty,regexp(DataTags,'thermistor'))==0))
    RespCol = find(cellfun(@isempty,regexp(DataTags,'thermistor'))==0);
else
    RespCol = find(cellfun(@isempty,regexp(DataTags,'respiration'))==0);
end
LickCol = find(cellfun(@isempty,regexp(DataTags,'Licks'))==0);
TrialCol = find(cellfun(@isempty,regexp(DataTags,'TrialON'))==0);
RewardCol = find(cellfun(@isempty,regexp(DataTags,'Rewards'))==0);

%% Mark Open Loop Replay trials (if any)
% find the stretch of open loop recording trials
OL_Blocks  = numel(find(diff(MySettings(:,32))==1)); % in timestamps
OL_Starts  = MySettings(find(diff(MySettings(:,32))== 1)+1,1); % in timestamps
OL_Stops   = MySettings(find(diff(MySettings(:,32))==-1)+1,1);
Replay_Starts = MySettings(find(diff(MySettings(:,32))== 2)+1,1);

if ~isempty(Replay_Starts)
    alltargets = [1:0.25:3.75];
    disp([num2str(OL_Blocks), ' Replay sessions found']);
    
    Replay.CloseLoopTraceTags    = {'TrialIdx'; ...
        'Lever'; ...
        'Motor'; ...
        'Encoder'; ...
        'Sniffs'; ...
        'Licks'; ...
        'TrialON'; ...
        'Rewards'; ...
        'TargetZone'; ...
        'OdorON';...
        'TimeStamps'};
    
    Replay.ReplayTraceTags       = {'PutativeTrialIdx'; ...
        'Lever'; ...
        'Motor'; ...
        'Encoder'; ...
        'Sniffs'; ...
        'Licks'; ...
        'SampleNumber';...
        'Rewards'; ...
        'TimeStamps'};
    
    
    
    for thisBlock = 1:OL_Blocks
        FirstTrial = find(TrialInfo.SessionTimestamps(:,1)>=OL_Starts(thisBlock),1,'first');
        LastTrial = find(TrialInfo.SessionTimestamps(:,1)<OL_Stops(thisBlock),1,'last');
        
        MyTrials = [FirstTrial:LastTrial];
        
        % get long concatenated vectors for analysis later
        % one sec (startoffset) before trial ON to one sec before next trial
        MyTraces = [];
        for i = 1:numel(MyTrials)
            thisTrial = MyTrials(i);
            
            % trace markers
            start_idx = TrialInfo.SessionIndices(thisTrial,1) - startoffset*SampleRate; % w.r.t. trial ON
            stop_idx  = TrialInfo.SessionIndices(thisTrial+1,1) - startoffset*SampleRate - 1;
            offset    = TrialInfo.Offset(thisTrial);
            
            % get the OdorOn trace using the OdorON info from OEPS
            OdorOnTrace = MyData(start_idx:stop_idx, TrialCol);
            OdorOnTrace(OdorOnTrace>0) = 1;
            OnIdx = find(OdorOnTrace,1,'first');
            OdorOnIdx = OnIdx - round(TTLs.Trial(thisTrial,4)*SampleRate);
            OdorOnTrace(OdorOnIdx:OnIdx,:) = 1;
            OdorOnTrace(find(OdorOnTrace)) = TTLs.Trial(thisTrial,5);

            MyTraces = [MyTraces; ...
            i+0*MyData(offset + (start_idx:stop_idx), LeverCol) ...
                MyData(offset + (start_idx:stop_idx), LeverCol) ...
                MyData(offset + (start_idx:stop_idx), MotorCol) ...
                MyData(offset + (start_idx:stop_idx), EncoderCol) ...
                MyData(offset + (start_idx:stop_idx), RespCol) ...
                MyData(start_idx:stop_idx, LickCol) ...
                MyData(start_idx:stop_idx, TrialCol) ...
                MyData(start_idx:stop_idx, RewardCol) ...
                alltargets(TrialInfo.TargetZoneType(thisTrial))+0*MyData(start_idx:stop_idx, LeverCol) ...
                OdorOnTrace ...
                MyData(start_idx:stop_idx, 1) ...
                ];
        end
        
        Replay.CloseLoopTraces(thisBlock) = {MyTraces};
        Replay.CloseLoopTrialIDs(thisBlock) = {MyTrials};
        
        % Get all replay trials belonging to this OL strectch
        if thisBlock<OL_Blocks
            ReplayTrials = find(Replay_Starts<OL_Starts(thisBlock+1));
        else
            ReplayTrials = find(Replay_Starts>OL_Starts(thisBlock));
        end
        
        MyReplayIDs = [];
        whichreplay = 0;
        for thisReplay = 1:numel(ReplayTrials)
%             
%             if thisBlock == 1 && thisReplay == 2
%                 keyboard;
%             end
% %             thisBlock
% %             thisReplay

            % find the corresponding behavior trial 
            trialIdx = find(TrialInfo.SessionTimestamps(:,1)>=Replay_Starts(ReplayTrials(thisReplay)),1,'first');
            
            % using the ephys TTLs - create a matrix of putative trialON
            % and OFF timestamps during replay
            
            % find Trial timestamps for this trial in the oeps file
            TS = TTLs.Trial(trialIdx,:);
            
            % find all odor valve transitions within this replay
            ValveEvents = [];
            for thisOdor = 1:3
                myEvents = intersect(find(TTLs.(['Odor',num2str(thisOdor)])(:,2)>(TS(1,1)+0.05)),...
                    find(TTLs.(['Odor',num2str(thisOdor)])(:,1)<TS(1,2)));
                myTimeStamps = TTLs.(['Odor',num2str(thisOdor)])(myEvents,:);
                ValveEvents = vertcat(ValveEvents,...
                    [myTimeStamps thisOdor*ones(numel(myEvents),1)]);
            end
            % Resort ValveEvents by occurence order
            [~,I] = sort(ValveEvents(:,1));
            ValveEvents = ValveEvents(I,:);
            
            % store for future analysis of spikes etc
            TTLs.Replay(thisBlock,thisReplay) = {[[TS(1,1) - startoffset; ValveEvents(1:end-1,2)] ValveEvents(:,2)]};

            % define Trial Off times w.r.t. to replay start in OEPS base
            TrialOff = ValveEvents(:,2) - TS(1,1); % w.r.t. trial start
            
            if size(TrialOff,1)>1 % otherwise it was not a replay trial 
                whichreplay = whichreplay + 1;
                % redefine Trial Off w.r.t. replay start in MATLAB - Behavior
                TrialOff = TrialInfo.SessionTimestamps(trialIdx,1) + TrialOff; % in behavior timebase
                
                % Get the actual replay trace recorded by MATLAB
                start_idx = TrialInfo.SessionIndices(trialIdx,1) - startoffset*SampleRate; % w.r.t. trial ON
                stop_idx  = TrialInfo.SessionIndices(trialIdx+1,1) - startoffset*SampleRate - 1;
                offset    = TrialInfo.Offset(trialIdx);
                
                MyReplayTrace = [ ...
                    0*MyData(offset + (start_idx:stop_idx), LeverCol) ...
                    MyData(offset + (start_idx:stop_idx), LeverCol) ...
                    MyData(offset + (start_idx:stop_idx), MotorCol) ...
                    MyData(offset + (start_idx:stop_idx), EncoderCol) ...
                    MyData(offset + (start_idx:stop_idx), RespCol) ...
                    MyData(start_idx:stop_idx, LickCol) ...
                    (start_idx:stop_idx)' - start_idx + 1 ...
                    MyData(start_idx:stop_idx, RewardCol) ...
                    MyData(start_idx:stop_idx, 1) ...
                    ];
                
                % initialize a new trace the same length as the closed-loop trace
                MyAdjustedReplayTrace = NaN*Replay.CloseLoopTraces{thisBlock}(:,1:9);
                
                % patch in samples into this NaN trace by aligning to TrialOFF
                % time points
                start_idx = 0;
                chunking_indices = [];
                for chunkedTrial = 1:size(Replay.CloseLoopTrialIDs{thisBlock},2)
                    % get the trace to be patched in
                    [~,stop_idx] = min(abs(MyReplayTrace(:,end) - TrialOff(chunkedTrial)));
                    trace_snippet = MyReplayTrace(start_idx+1:stop_idx,:);
                    start_idx = stop_idx;
                    trace_snippet(:,1) = trace_snippet(:,1) + chunkedTrial;
                    snippet_size = size(trace_snippet,1);
                    % find the place where the trace should be patched in
                    % i.e. Indice corresponding to TrialOFF in the original
                    % trace
                    trial_off_idx = find(Replay.CloseLoopTraces{thisBlock}(:,end) == ...
                        TrialInfo.SessionTimestamps(Replay.CloseLoopTrialIDs{thisBlock}(chunkedTrial),2));
                    patch_start = trial_off_idx-snippet_size+1;
                    while patch_start<1
                        trace_snippet(1,:) = [];
                        patch_start = patch_start + 1;
                    end
                    MyAdjustedReplayTrace(patch_start:trial_off_idx,:) = trace_snippet;
                    chunking_indices = [chunking_indices; trial_off_idx];
                end
                
                Replay.ReplayTraces(thisBlock,whichreplay) = {MyAdjustedReplayTrace};
                Replay.ReplayChunks(thisBlock,whichreplay) = {chunking_indices/SampleRate};
%                 Replay.ReplayTracesOriginal(thisBlock,whichreplay) = {MyReplayTrace};
                
                MyReplayIDs = [MyReplayIDs; trialIdx];
            end
        end
        Replay.ReplayTrialIDs(thisBlock) = {MyReplayIDs};
    end
else
    Replay = [];
end

% plot - sanity checks
figure;
for i = 1:size(Replay.CloseLoopTrialIDs,2)
    subplot(size(Replay.CloseLoopTrialIDs,2),1,i);
    hold on;
    plot(Replay.CloseLoopTraces{i}(:,3),'k');
    for j = 1:size(Replay.ReplayTrialIDs{i},1)
        plot(Replay.ReplayTraces{i,j}(:,3),'r');
    end
end
end
