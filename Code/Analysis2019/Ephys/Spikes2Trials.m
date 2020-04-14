function [cluster, EphysTuningTrials] = Spikes2Trials(myKsDir, TS, TrialInfo, TuningTrials)
if nargin<2
    TS = [];
    TrialInfo = [];
    TuningTrials = [];
end
EphysTuningTrials = [];

global startoffset; % = 1; % seconds

%% add the relevant repositories to path
addpath(genpath('/opt/afterphy'))
addpath(genpath('/opt/spikes'))
addpath(genpath('/opt/npy-matlab'))
addpath(genpath('/opt/open-ephys-analysis-tools'))

%% defaults
sampleRate = 30000; % Open Ephys acquisition rate

%% Filepaths
% myKsDir = '/mnt/analysis/N8/2019-01-26_19-24-28'; % directory with kilosort output

%% Get Trial Timestamps from the OpenEphys Events file
filename = fullfile(myKsDir,'all_channels.events');
[data, timestamps, info] = load_open_ephys_data(filename); % data has channel IDs

% adjust for clock offset between open ephys and kilosort
[offset] = AdjustClockOffset(myKsDir);
offset = offset/sampleRate;
timestamps = timestamps - offset;

% Get various events
TTLTypes = unique(data);
Tags = {'Air', 'Odor1', 'Odor2', 'Odor3', 'Trial', 'Reward'};
for i = 1:numel(TTLTypes)
    On = timestamps(intersect(find(info.eventId),find(data==TTLTypes(i))));
    Off = timestamps(intersect(find(~info.eventId),find(data==TTLTypes(i))));
    % delete the first off value, if it preceeds the On
    Off(Off<On(1)) = [];
    On(On>Off(end)) = [];
    TTLs.(char(Tags(i))) = [On Off Off-On];
end

%% Compare Trial Events to Behavior file

%% Hacks
%find(abs(TTLs.Trial(1:size(TS,1),3)-TS(:,3))>0.1,1,'first');
if strcmp(myKsDir,'/mnt/data/Priyanka/K4/2019-12-19_15-42-09')
    TTLs.Trial(1,:) = [];
    TTLs.Trial([181,217],:) = []; % delete trials that didn't match
end

if strcmp(myKsDir,'/mnt/data/Priyanka/K4/2019-12-19_16-06-24')
    TTLs.Trial([82,116,147,166],:) = []; % delete trials that didn't match
end

if strcmp(myKsDir,'/mnt/data/Priyanka/K4/2020-01-03_13-33-16')
    TTLs.Trial([2,257,336,375],:) = []; % delete trials that didn't match
end

if strcmp(myKsDir,'/mnt/data/Priyanka/K1/2019-12-19_16-40-05')
    TTLs.Trial([1,115,136,156,226,252,294],:) = []; % delete trials that didn't match
end

if strcmp(myKsDir,'/mnt/data/Priyanka/K1/2020-01-03_14-15-05')
    TTLs.Trial([1,95,114,132],:) = []; % delete trials that didn't match
end

if strcmp(myKsDir,'/mnt/data/Priyanka/K1/2020-01-31_11-59-46')
    TTLs.Trial([68,83,96,99],:) = []; % delete trials that didn't match
end

do_tuning = 0;
%% Account for Tuning Trials (if any)
if ~isempty(TuningTrials)
    if (size(TTLs.Trial,1) - size(TS,1)) >= size(TuningTrials,1)
        EphysTuningTrials = TTLs.Trial(size(TS,1)+1:end,:);
        TTLs.Trial(size(TS,1)+1:end,:) = [];
        
        % delete any values with trial duration < avg. tuning trial
        % duration
        foo = find(EphysTuningTrials(:,3)<floor(min(TuningTrials(:,7))));
        EphysTuningTrials(foo,:) = [];
        
        % Assign odor identities
        for i = 1:size(EphysTuningTrials,1)
            tstart = EphysTuningTrials(i,1);
            tstop = EphysTuningTrials(i,2);
            O1 = intersect(find(TTLs.Odor1(:,1)>tstart),find(TTLs.Odor1(:,1)<tstop)); 
            O2 = intersect(find(TTLs.Odor2(:,1)>tstart),find(TTLs.Odor2(:,1)<tstop));
            O3 = intersect(find(TTLs.Odor3(:,1)>tstart),find(TTLs.Odor3(:,1)<tstop));
            if ~isempty(O1)
                EphysTuningTrials(i,4) = 2;
                EphysTuningTrials(i,5:7) = TTLs.Odor1(O1,:);
            elseif ~isempty(O2)
                EphysTuningTrials(i,4) = 3;
                EphysTuningTrials(i,5:7) = TTLs.Odor2(O2,:);
            elseif ~isempty(O3)
                EphysTuningTrials(i,4) = 4;
                EphysTuningTrials(i,5:7) = TTLs.Odor3(O3,:);
            else
                EphysTuningTrials(i,4) = 1;
            end
        end
        
        % Align the ephys and behavior trial lists 
        idx = strfind(EphysTuningTrials(:,4)',TuningTrials(2:end,2)');
        EphysTuningTrials(1:idx-2,:) = [];
        EphysTuningTrials(size(TuningTrials,1)+1:end,:) = [];

        if ~any(EphysTuningTrials(2:end,4)-TuningTrials(2:end,2))
            display('odor sequences match');
            do_tuning = 1;
        else
            display('odor sequences do not match');
            keyboard;
        end
    else
        EphysTuningTrials = [];
    end
end

%% Load data from kilosort/phy
% sp.st are spike times in seconds (for all spikes)
% sp.clu are cluster identities (for all spikes)
% sp.cids is list of unqiue clusters
% sp.cgs are cluster defs (1 = MUA, 2 = good, 3 = Unsorted??) (1/cluster)
% spikes from clusters labeled "noise" have already been omitted
sp = loadKSdir(myKsDir);

%% Split data by clusters and by trials

% align to trial off of the previous trial
for mycluster = 1:length(sp.cids) % for each cluster
    
    % only process clusters that were labeled as good
    if sp.cgs(mycluster) == 2
        allspikes = sp.st(sp.clu==sp.cids(mycluster)); % in seconds
        whichtrial = allspikes*0;
        clear spiketimes
        
        % Assign spikes to trials
        for mytrial = 1:size(TTLs.Trial,1)
            tstart = TTLs.Trial(mytrial,1) - startoffset;
            if mytrial < size(TTLs.Trial,1)
                tstop = TTLs.Trial(mytrial+1,1) - startoffset;
            else
                tstop = TTLs.Trial(mytrial,2) + startoffset;
            end
            myspikes = allspikes(find(allspikes>=tstart & allspikes<tstop));
            myspikes = myspikes - tstart;
            spiketimes(mytrial) = {myspikes};
        end
        
        if do_tuning
            % Assign spikes to trials
            for mytrial = 1:size(EphysTuningTrials,1)
                tstart = EphysTuningTrials(mytrial,1);
                tstop = EphysTuningTrials(mytrial,2);
                myspikes = allspikes(find(allspikes>=tstart & allspikes<tstop));
                myspikes = myspikes - tstart;
                tuningspiketimes(mytrial) = {myspikes};
            end
        end
        
%         % get all waveforms for this cluster
%         gwfparams.dataDir = myKsDir;                % KiloSort/Phy output folder
%         gwfparams.fileName = 'mybinaryfile.dat';    % .dat file containing the raw
%         gwfparams.dataType = 'int16';               % Data type of .dat file (this should be BP filtered)
%         gwfparams.nCh = 32;                         % Number of channels that were streamed to disk in .dat file
%         gwfparams.wfWin = [-40 41];              % Number of samples before and after spiketime to include in waveform
%         gwfparams.nWf = 2000;                    % Number of waveforms per unit to pull out
%         gwfparams.spikeTimes =    allspikes*sampleRate; % Vector of cluster spike times (in samples) same length as .spikeClusters
%         gwfparams.spikeClusters = sp.cids(mycluster) + 0*gwfparams.spikeTimes; % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
%         wf = getWaveForms(gwfparams);
%         %imagesc(squeeze(wf.waveFormsMean))
%         
%         [~,channels] = sort(std(squeeze(wf.waveFormsMean),0,2),'descend');
%         channels = ceil(channels/4);
%         tetrode = mode(channels(1:4));
        
        cluster(mycluster).id = sp.cids(mycluster);
%         cluster(mycluster).tetrode = tetrode;
        cluster(mycluster).spikecount = numel(allspikes);
        cluster(mycluster).spikes = spiketimes;
        if do_tuning
            cluster(mycluster).tuningspikes = tuningspiketimes;
        end
%         for i = 1:4
%             cluster(mycluster).meanwaveform(i,:) = nanmean(squeeze(wf.waveForms(1,:,i+(tetrode-1)*4,:)),1);
%             cluster(mycluster).stdwaveform(i,:) = nanstd(squeeze(wf.waveForms(1,:,i+(tetrode-1)*4,:)),1);
%         end
        
    end
end

disp(['found ',num2str(mycluster),' units']);
end
