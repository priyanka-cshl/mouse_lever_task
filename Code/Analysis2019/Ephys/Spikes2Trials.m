function [SingleUnits] = Spikes2Trials(TTLs, SingleUnits)

%% function to label spike times by trials
% inputs: TTLs - Trial On-Off times (offset corrected) in Oeps timebase

%% defaults
sampleRate = 30000; % Open Ephys acquisition rate
global startoffset; % = 1; % seconds

% align to trial off of the previous trial
for myUnit = 1:length(SingleUnits) % for each cluster
    
    allspikes = SingleUnits(myUnit).spikes; % in seconds
    SingleUnits(myUnit).trialtags = NaN*allspikes;
    SingleUnits(myUnit).trialalignedspikes = allspikes;
    
    % Assign spikes to trials
    for mytrial = 1:size(TTLs.Trial,1)
        tstart = TTLs.Trial(mytrial,1) - startoffset;
        if mytrial < size(TTLs.Trial,1)
            tstop = TTLs.Trial(mytrial+1,1) - startoffset;
        else
            tstop = TTLs.Trial(mytrial,2) + startoffset;
        end
        SingleUnits(myUnit).trialtags(find(allspikes>=tstart & allspikes<tstop)) = mytrial;
        SingleUnits(myUnit).trialalignedspikes(find(allspikes>=tstart & allspikes<tstop)) = ...
            SingleUnits(myUnit).spikes(find(allspikes>=tstart & allspikes<tstop)) - ...
            tstart;
    end
    
end
end
