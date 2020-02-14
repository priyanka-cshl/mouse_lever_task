function [] = PlotOdorArmTuning(whichcluster,Traces,TrialInfo,spiketimes)
global subplotcol
global SampleRate;
% initialize the 2D histogram - one for counting samples/bin
% other for counting spikes/bin

LeverBinsize = 0.25;
Leverbins = 0:LeverBinsize:5;
MotorBinsize = 12;
Motorbins = (-120:MotorBinsize:120);

SpikeHistogram = zeros(numel(Leverbins)-1,numel(Motorbins)-1);

for odor = 1:3
    whichtrials = intersect(find(TrialInfo.Odor==odor),find(TrialInfo.Perturbation(:,1)==0));
    LeverAll = [];
    MotorAll = [];
    SpikesAll = [];
    
    for trial = 1:numel(whichtrials)
            mytrial = whichtrials(trial);
            Lever = cell2mat(Traces.Lever(mytrial)); % in samples @500 Hz
            Motor = cell2mat(Traces.Motor(mytrial)); % in samples @500 Hz
            Spikes = cell2mat(spiketimes(whichcluster).spikes(TrialInfo.TrialID(mytrial))); % in seconds
            Spikes = round(SampleRate*Spikes); % put spikes in 2 ms bins to match the behavioral sampling rate    
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
        
    for nrow = 1:numel(Leverbins)-1
        for ncol = 1:numel(Motorbins)-1
            temp = intersect(find(LeverAll>=Leverbins(nrow) & LeverAll<(Leverbins(nrow)+LeverBinsize)),...
                find(MotorAll>=Motorbins(ncol) & MotorAll<(Motorbins(ncol)+MotorBinsize)));
%             if ~isempty(temp)
%                 disp
%             end
            SpikeHistogram(odor,nrow,ncol) = sum(SpikesAll(temp))/numel(temp); % normalized to account for oversampling
        end
    end
    SpikeHistogram(odor,:,:) = SampleRate*SpikeHistogram(odor,:,:); % convert to Hz
end

colormap(brewermap([],'*Greys'));
for odor = 1:3
    plotID = 6*(odor-1) + subplotcol;
    subplot(3,6,plotID);
    imagesc(squeeze(SpikeHistogram(odor,:,:)));
    set(gca,'YTick', [], 'XTick', []);
    axis('square');
end

end