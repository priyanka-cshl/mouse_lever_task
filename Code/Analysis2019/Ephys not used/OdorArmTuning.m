function [] = OdorArmTuning(Behavior, Physiology)

% defaults
LeverBinsize = 0.25;
Leverbins(:,1) = 0:LeverBinsize:(5-LeverBinsize);  
Leverbins(:,2) = Leverbins(:,1) + LeverBinsize;

MotorBinsize = 5;
Motorbins(:,1) = -100:MotorBinsize:(100-MotorBinsize);
Motorbins(:,2) = Motorbins(:,1) + MotorBinsize;


% Histogram of Firing rate as a function of Odor location
for thisReplay = 1:size(Physiology,2)    
    Odor = Behavior(thisReplay).Odor;
    %Trial = Behavior(thisReplay).Trial;
    for thisTrial = 1:size(Physiology(thisReplay).PSTH,1)
        for thisUnit = 1:size(Physiology(thisReplay).PSTH,3)
            % odor location
            for thisOdor = 0:1:3
                
                relevantBins = find(Odor==thisOdor);
                myFR = Physiology(thisReplay).PSTH(thisTrial,relevantBins,thisUnit);
                myLocations = Behavior(thisReplay).Motor(relevantBins,thisTrial);
                myOdorTuning(thisReplay,thisUnit,thisTrial,thisOdor+1) = {TuningCurve(myLocations,myFR,Motorbins)};
            end
            
            % lever location
            relevantBins = find(Odor==0); % odor OFF
            myFR = Physiology(thisReplay).PSTH(thisTrial,relevantBins,thisUnit);
            myLocations = Behavior(thisReplay).Lever(relevantBins,thisTrial);
            myLeverTuning(thisReplay,thisUnit,thisTrial,1) = {TuningCurve(myLocations,myFR,Leverbins)};
            
            relevantBins = find(Odor>0); % odor ON
            myFR = Physiology(thisReplay).PSTH(thisTrial,relevantBins,thisUnit);
            myLocations = Behavior(thisReplay).Lever(relevantBins,thisTrial);
            myLeverTuning(thisReplay,thisUnit,thisTrial,2) = {TuningCurve(myLocations,myFR,Leverbins)};
                
        end
    end
end


    function [myCurve] = TuningCurve(XVar, YVar, Xbins)
        % XVar and YVar are vectors - same size
        % Xbins is a 2 column matrix - lower, upper bin
        for myBin = 1:size(Xbins,1)
            idx = find((XVar>=Xbins(myBin,1))&(XVar<Xbins(myBin,2)));
            if ~isempty(idx)
                myCurve(myBin,:) = [mean(YVar(idx)) std(YVar(idx)) numel(idx)];
            else
                myCurve(myBin,:) = [NaN NaN 0];
            end
                
        end
    end



%% plot the histograms
%figure('name',[char(MyFileName),'_',num2str(whichcluster),'_tuning']);
colormap(brewermap([],'*Greys'));
for odor = 1:3
    
    if subplotcol == 1
        % plot the lever histogram
        plotID = (6*2)*(odor-1) + 1;% [odor*2 -1, 1];
        subplot(6,6,plotID);
        imagesc(squeeze(FullHistogram(odor,:,:)));
        set(gca,'YTick', [], 'XTick', []);
        axis('square');
        
%         plotID = (6*2)*(odor-1) + 7;% [odor*2 -1, 1];
%         subplot(6,6,plotID);
%         imagesc(squeeze(FullHistogram2(odor,:,:)));
%         set(gca,'YTick', [], 'XTick', []);
%         axis('square');
    end
    
    % plot the spike histogram
    plotID = (6*2)*(odor-1) + 1 + subplotcol; %[odor*2 -1, subplotcol+1]; %(odor-1)*6 + subplotcol + 1;
    subplot(6,6,plotID);
    imagesc(squeeze(SpikeHistogram(odor,:,:)));
    set(gca,'YTick', [], 'XTick', []);
    axis('square');
    
    % plot the spike histogram
    plotID = (6*2)*(odor-1) + 7 + subplotcol; %[odor*2, subplotcol+1];
    subplot(6,6,plotID);
    imagesc(squeeze(ScrambleHistogram(odor,:,:)));
    set(gca,'YTick', [], 'XTick', []);
    axis('square');
end    
   
end

