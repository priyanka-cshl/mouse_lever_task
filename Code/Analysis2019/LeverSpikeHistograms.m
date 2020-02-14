function [FullHistogram, SpikeHistogram, OdorHistogram] = LeverSpikeHistograms(whichcluster, Traces, TrialInfo, spiketimes, perturb)

if nargin<5
    perturb = 0;
end

global MyFileName
global subplotcol
if subplotcol == 0
    subplotcol = 5;
end
global SampleRate;

%% Uncentered histograms (all TZs separate)
LeverBinsize = 0.25;
Leverbins = 0:LeverBinsize:5;  
MotorBinsize = 8;
Motorbins = (-120:MotorBinsize:120);

FullHistogram = zeros(4,12,numel(Leverbins)-1);
SpikeHistogram = zeros(4,12,numel(Leverbins)-1);
OdorHistogram = zeros(4,12,numel(Motorbins)-1);

for odor = 1:4
    for zone = 1:12
        if odor == 4
            whichtrials = intersect(find(TrialInfo.TargetZoneType==zone),find(TrialInfo.Odor==odor));
        else
            whichtrials = intersect(intersect(find(TrialInfo.TargetZoneType==zone),find(TrialInfo.Odor==odor)),find(TrialInfo.Perturbation(:,1)==perturb));
        end
        LeverAll = [];
        MotorAll = [];
        SpikesAll = [];
        for trial = 1:numel(whichtrials)
            mytrial = whichtrials(trial);
            Lever = cell2mat(Traces.Lever(mytrial)); % in samples @500 Hz
            Motor = cell2mat(Traces.Motor(mytrial)); % in samples @500 Hz
            Spikes = cell2mat(spiketimes(whichcluster).spikes(TrialInfo.TrialID(mytrial))); % in seconds
            Spikes = round(500*Spikes); % put spikes in 2 ms bins to match the behavioral sampling rate    
            SpikeCounts = Lever*0;
            for i = 1:size(Lever,1)
                SpikeCounts(i) = numel(find(Spikes==i));
            end
            
            start_idx = TrialInfo.TimeIndices(mytrial,1); % trial start in indices
            thisTrialRewards = cell2mat(TrialInfo.Reward(mytrial));
            if any(thisTrialRewards>0)
                stop_idx = thisTrialRewards(find(thisTrialRewards>0,1,'first')); % in seconds w.r.t. trace start
            else
                stop_idx = TrialInfo.Timestamps(mytrial,2);
            end
            stop_idx = round(stop_idx*SampleRate);
            LeverAll = [LeverAll; Lever(start_idx:stop_idx)];
            MotorAll = [MotorAll; Motor(start_idx:stop_idx)];
            SpikesAll = [SpikesAll; SpikeCounts(start_idx:stop_idx)];
        end
        
        % Make histograms
        for mybin = 1:numel(Leverbins)-1
            temp = find(LeverAll>=Leverbins(mybin) & LeverAll<(Leverbins(mybin)+LeverBinsize));
            FullHistogram(odor,zone,mybin) = numel(temp);
            SpikeHistogram(odor,zone,mybin) = sum(SpikesAll(temp))/numel(temp); % normalized to account for oversampling
        end
        
        FullHistogram(odor,zone,:) = FullHistogram(odor,zone,:)/sum(FullHistogram(odor,zone,:));
        
        
        SpikeHistogram(odor,zone,:) = 500*SpikeHistogram(odor,zone,:); % convert to Hz
        
        for mybin = 1:numel(Motorbins)-1
            temp = find(MotorAll>=Motorbins(mybin) & MotorAll<(Motorbins(mybin)+MotorBinsize));
%             if ~isempty(temp)
%                 OdorHistogram(odor,zone,mybin) = sum(SpikesAll(temp))/numel(temp); % normalized to account for oversampling
%             else
%                 OdorHistogram(odor,zone,mybin) = NaN;
%             end
            OdorHistogram(odor,zone,mybin) = numel(temp);
        end
%         OdorHistogram(odor,zone,:) = 500*OdorHistogram(odor,zone,:);
           OdorHistogram(odor,zone,:) = OdorHistogram(odor,zone,:)/sum(OdorHistogram(odor,zone,:));
        
    end
end

% %% plot the histograms
% %figure('name',[char(MyFileName),'_',num2str(whichcluster),'_tuning']);
% colormap(brewermap([],'*Greys'));
% for odor = 1:3
%     
%     if subplotcol == 1
%         % plot the lever histogram
%         plotID = (6*2)*(odor-1) + 1;% [odor*2 -1, 1];
%         subplot(6,6,plotID);
%         imagesc(squeeze(FullHistogram(odor,:,:)));
%         set(gca,'YTick', [], 'XTick', []);
%         axis('square');
%     end
%     
%     % plot the spike histogram
%     plotID = (6*2)*(odor-1) + 1 + subplotcol; %[odor*2 -1, subplotcol+1]; %(odor-1)*6 + subplotcol + 1;
%     subplot(6,6,plotID);
%     imagesc(squeeze(SpikeHistogram(odor,:,:)));
%     set(gca,'YTick', [], 'XTick', []);
%     axis('square');
%     
%     % plot the odor tuning
%     % plot the spike histogram
%     plotID = (6*2)*(odor-1) + 7 + subplotcol; %[odor*2, subplotcol+1];
%     subplot(6,6,plotID);
%     imagesc(squeeze(OdorHistogram(odor,:,:)));
%     set(gca,'YTick', [], 'XTick', []);
%     axis('square');
% end    
   
end

