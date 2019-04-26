% organize the session data into a cell array of trials
function [Traces, CamA, CamB, TrialInfo] = ParseTrialsVideoSync(MyData)

SampleRate = 500; % = 500; % samples/second

% Get Column IDs
TrialCol = find(cellfun(@isempty,regexp(WhatsMyData','Trial'))==0);
LeverCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
MotorCol = find(cellfun(@isempty,regexp(WhatsMyData','MotorPosition'))==0);
LickCol = find(cellfun(@isempty,regexp(WhatsMyData','Licks'))==0);
RewardCol = find(cellfun(@isempty,regexp(WhatsMyData','Water'))==0);
RespCol = find(cellfun(@isempty,regexp(WhatsMyData','Respiration'))==0);
CamCol = find(cellfun(@isempty,regexp(WhatsMyData','Camerasync'))==0); % to get camera triggers

%% Get Trial ON-OFF timestamps
TrialColumn = MyData(:,TrialCol);
TrialColumn(TrialColumn~=0) = 1; % make logical
TrialOn = find(diff(TrialColumn)>0);
TrialOff =  find(diff(TrialColumn)<0)+1;

% account for cases where acquisition started/ended in between a trial
while TrialOn(1)>TrialOff(1)
    TrialOff(1,:) = [];
end
while TrialOn(end)>TrialOff(end)
    TrialOn(end,:) = [];
end

camTrials = 0;
% Crunch data trial-by-trial
for thisTrial = 1:length(TrialOn)-1 % ignore the last trial
    
    
    %% 1: extract continuous traces for lever, motor position, licks and sniffs
    start_offset = 0;
    start_idx = TrialOn(thisTrial);    
    stop_idx = TrialOn(thisTrial+1); % until end of current trial
    
    %% check if video was being acquired in this trial
    if any(MyData(start_idx:stop_idx, CamCol) & MyData(start_idx:stop_idx, TrialCol))
        camTrials = camTrials + 1;
        % Extract traces
        Traces.Lever(camTrials) = { MyData(start_idx:stop_idx, LeverCol) };
        Traces.Motor(camTrials) = { MyData(start_idx:stop_idx, MotorCol) };
        Traces.Sniffs(camTrials) = { MyData(start_idx:stop_idx, RespCol) };
        Traces.Licks(camTrials) = { MyData(start_idx:stop_idx, LickCol) };
        Traces.Cams(camTrials) = { MyData(start_idx:stop_idx, [CamCol CamCol+1]) };
        Traces.Timestamps(camTrials) = { (1:numel(MyData(start_idx:stop_idx, LeverCol)))/SampleRate };
        
        CamATriggers = find(diff([0; MyData(start_idx:stop_idx, CamCol+1)])==1);
        CamBTriggers = find(diff([0; MyData(start_idx:stop_idx, CamCol+1)])==1);
        
        CamA.NumFrames(camTrials) = numel(CamATriggers);
        CamA.Indices(camTrials) = { CamATriggers };
        CamA.Timestamps(camTrials) = { CamATriggers/SampleRate };
        
        CamB.NumFrames(camTrials) = numel(CamBTriggers);
        CamB.Indices(camTrials) = { CamBTriggers };
        CamB.Timestamps(camTrials) = { CamBTriggers/SampleRate };
        
        TrialInfo.TrialID(camTrials) = thisTrial;
    end
end
