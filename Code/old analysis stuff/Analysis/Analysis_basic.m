% choose data file(s) and parse data into a struct
[Data] = ExtractSessionData();

session_num = 1;

MyData = Data.(['session',num2str(session_num)]).data;
% for plotting
%RecreateSession(MyData);
    
% Reorganize data into trials
[Lever, TrialInfo, Zones] = SortSessionByTrials(MyData);
    
% get rid of zones with less than 5 trials
ZonesToUse = [];
for i = 1:size(Zones,1)
    if Zones(i,3)>5
        ZonesToUse = [ZonesToUse; i];
    end
end

Odors = unique(TrialInfo.Odor);

% find the length of the longest trial
timepoints_all = cellfun(@numel, Lever);
timepoints_max = max(timepoints_all);

% reformat 'Lever' cell array to a matrix, pad short trials with NaNs
% for successes, only use time-points until reward delivery - NaNs after
clear Lever_mat;
for i = 1:size(Lever,2)
    timepoints_to_keep = timepoints_all(i); % length of the trial
    if TrialInfo.Success(i) % successful trial
        % truncate trial at time of reward delivery
        timepoints_to_keep = TrialInfo.Reward{i};
    end
    Lever_mat(i,1:timepoints_to_keep) = Lever{i}(1:timepoints_to_keep);
    timepoints_to_keep = timepoints_to_keep + 1;
    if timepoints_to_keep<=timepoints_max
        Lever_mat(i,timepoints_to_keep:timepoints_max) = NaN;
    end
end

% align all trials by trial time start
max_offset = max(cell2mat(cellfun(@min,TrialInfo.StayTimeStart,'UniformOutput',false)'));
Lever_mat(:,end+1:end+max_offset) = NaN; % padding for trial shifting
for i = 1:size(Lever,2)
    if min(TrialInfo.StayTimeStart{i}) < max_offset
        temp_offset = max_offset - min(TrialInfo.StayTimeStart{i});
        Lever_mat(i,:) = circshift(Lever_mat(i,:),[1,temp_offset]);
        Lever_mat(i,1:temp_offset) = NaN;
    end
end

% sort trials by target zones and by odor
% h1 = figure('Name','Successes'); % successes 
% h2 = figure('Name','Failures'); % successes 
% h3 = figure('Name','Averages');
h4 = figure;
for i = 1:numel(Odors)
    for j = 1:numel(ZonesToUse)
%         plot_num = (i-1)*numel(ZonesToUse) + j;
%         
%         for m = 1:3
%             figure(eval(['h',num2str(m)]));
%             subplot(numel(Odors),numel(ZonesToUse),plot_num);
%             hold on;
%             % plot target zone
%             fill([1 1 size(Lever_mat,2) size(Lever_mat,2)], ...
%                 [Zones(ZonesToUse(j),2) Zones(ZonesToUse(j),1) Zones(ZonesToUse(j),1) Zones(ZonesToUse(j),2)], ...
%                 [1 1 0],'FaceAlpha',0.2,'EdgeColor','none')
%             line([max_offset max_offset], [-1 5], 'color', 'k', 'Linestyle', ':');
%         end
%         
%         f =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==1);
%         figure(h1);
%         plot(Lever_mat(f,:)','k');
%         figure(h3);
%         MyMean = Mean_NoNaNs(Lever_mat(f,:));
%         plot(MyMean(1,:),'k');
%         plot(MyMean(1,:)+MyMean(4,:),':k');
%         plot(MyMean(1,:)-MyMean(4,:),':k');
%         
%         f =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==0);
%         figure(h2);
%         plot(Lever_mat(f,:)','r');
%         figure(h3);
%         MyMean = Mean_NoNaNs(Lever_mat(f,:));
%         plot(MyMean(1,:),'r');
%         plot(MyMean(1,:)+MyMean(4,:),':r');
%         plot(MyMean(1,:)-MyMean(4,:),':r');
        
        f =  find( (TrialInfo.Odor==Odors(i)) & (TrialInfo.TargetZoneType==ZonesToUse(j)) & TrialInfo.Success==0);
        figure(h4);
        subplot(1,numel(Odors),i); hold on
        if j == 1
            line([max_offset max_offset], [-1 5], 'color', 'k', 'Linestyle', ':');
        end
        MyMean = Mean_NoNaNs(Lever_mat(f,:));
        colormat = [0 0 0];
        colormat(j) = 1;
        plot(MyMean(1,:),'color',colormat);
        plot(MyMean(1,:)+MyMean(4,:),':','color',colormat);
        plot(MyMean(1,:)-MyMean(4,:),':','color',colormat);
        
    end
end
