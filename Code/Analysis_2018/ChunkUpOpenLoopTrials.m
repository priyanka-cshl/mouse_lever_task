% organize the session data into a cell array of trials
function [Data, Motor, TrialInfo, Respiration] = ChunkUpOpenLoopTrials(MyData, TrialSequence, deletefirsttrial)

% column ID for trial column
TrialCol = find(cellfun(@isempty,regexp(WhatsMyData','Trial'))==0);
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

if size(TrialOn,1)>size(TrialSequence,1)
    % delete first trial
    TrialOn(1,:) = [];
    TrialOff(1,:) = [];
end

if deletefirsttrial
    TrialOn(1,:) = [];
    TrialOff(1,:) = [];
end
    
% delete trial time stamps that are beyond the trials in the
% trialsequence
if size(TrialOn,1)>size(TrialSequence,1)
    TrialOn(size(TrialSequence,1)+1:end,:) = [];
    TrialOff(size(TrialSequence,1)+1:end,:) = [];
end

% Crunch data trial-by-trial
DataCol = find(cellfun(@isempty,regexp(WhatsMyData','Lever'))==0);
RewardCol = find(cellfun(@isempty,regexp(WhatsMyData','Water'))==0);
OdorOnCol = find(cellfun(@isempty,regexp(WhatsMyData','InRewardZone'))==0);
if size(MyData,2)>12
    EncoderCol = find(cellfun(@isempty,regexp(WhatsMyData','RotaryEncoder'))==0);
    MotorCol = find(cellfun(@isempty,regexp(WhatsMyData','MotorPosition'))==0);
    HomeCol = find(cellfun(@isempty,regexp(WhatsMyData','HomeSensor'))==0);
    RespCol = find(cellfun(@isempty,regexp(WhatsMyData','Respiration'))==0);
end

for t = 1:length(TrialOn)
    
    %% populate two cell arays - TrialInfo and Lever and Motor
    Data(t) = { MyData(TrialOn(t):TrialOff(t), DataCol) };
    Motor(t) = { MyData(TrialOn(t):TrialOff(t), MotorCol) };
    Respiration(t) = { MyData(TrialOn(t):TrialOff(t), RespCol) };
    
    TrialInfo.Timestamps(t,:) = MyData([TrialOn(t) TrialOff(t)],1);
    TrialInfo.TimeIndices(t,:) = [TrialOn(t) TrialOff(t)];
    TrialInfo.Odor(t,1) = TrialSequence(t,2);
    TrialInfo.TargetZoneType(t,1) = TrialSequence(t,1);
    TrialInfo.Reward(t) = { find( diff( MyData(TrialOn(t):TrialOff(t), RewardCol) )==1 ) };
    TrialInfo.Length(t) = TrialOff(t) - TrialOn(t) + 1;

    % Calculate all stay times
    TrialInfo.StayTime(t) = {  find( diff( [ MyData(TrialOn(t):TrialOff(t), OdorOnCol); 0] )==-1 ) - find( diff( [0; MyData(TrialOn(t):TrialOff(t), OdorOnCol)] )==1 ) + 1 };
    TrialInfo.StayTimeStart(t) = { find( diff( [0; MyData(TrialOn(t):TrialOff(t), OdorOnCol)] )==1 ) };
    TrialInfo.TrialID(t) = t; % original trial ID - some trials may get deleted because of weird target zones
    
end

end