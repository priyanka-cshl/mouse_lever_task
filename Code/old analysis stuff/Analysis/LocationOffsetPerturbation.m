% function [] = LocationOffsetPerturbation()
Results = [];
% load the trajectories
load(AllSessions(i).name, 'Trajectories');

% combine different offsets

TrajectoryStats(find(TrajectoryStats(:,8)<121 & TrajectoryStats(:,8)>0),8) = -1;
TrajectoryStats(find(TrajectoryStats(:,8)>121),8) = 1;

MyOffsets = unique(TrajectoryStats(find(TrajectoryStats(:,7)==6),8));

%if numel(MyOffsets)==4

% only proceed if there are atleast 5 offset trials each
if numel(find(TrajectoryStats(find(TrajectoryStats(:,7)==6),8)==1))<5 || ...
   numel(find(TrajectoryStats(find(TrajectoryStats(:,7)==6),8)==-1))<5
    return;
end
    
% for plotting
%foo = colormap(brewermap([17],'Spectral'));
foo = colormap(brewermap([11],'RdBu'));
% if numel(MyOffsets)>2
%     mycolors = foo([1 4 14 17],:);
% else
%     mycolors = foo([4 14],:);
% end
mycolors = foo([2 end-1],:);

preperturbationwindow = 200;
figure('Name',AllSessions(i).name);
subplot(2,1,1); hold on
subplot(2,1,2); hold on

tag = '';

for j = 1:numel(MyOffsets) % for each offset
    idx = find((TrajectoryStats(:,7)==6)&(TrajectoryStats(:,8)==MyOffsets(j)));
    
    if numel(idx) < 5
        close(gcf);
        return;
    end
    tag = [tag,num2str(numel(idx)),' '];
    pstart = TrajectoryStats(idx,9) - preperturbationwindow; % time at which feedback was turned off
    
    % get relevant trials
    MyLever = Trajectories.Lever(idx,:);
    
    % chop off unnecessary samples from the beginning of the trial
    subplot(2,1,1);
    for k = 1:size(MyLever,1)
        mytrace = circshift(MyLever(k,:),-pstart(k));
        mytrace(1,end-pstart(k):end) = NaN;
        MyLever(k,:) = mytrace;
        plot(1:length(mytrace),mytrace,'color',mycolors(j,:));
    end
    line([1 length(mytrace)],[2.5 2.5],...
        'color','k','LineStyle','--','Linewidth',1);
    line([preperturbationwindow preperturbationwindow],[0 5],...
        'color','k','LineStyle','--','Linewidth',1);
    set(gca,'XLim',[1 1000+preperturbationwindow],'YLim',[0 5]);
    
    % plot the average trace as well
    subplot(2,1,2);
    MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
        std(MyLever,'omitnan')/sqrt(numel(idx)),...
        mycolors(j,:),[],0.5);
    line([1 length(mytrace)],[2.5 2.5],...
        'color','k','LineStyle','--','Linewidth',1);
    line([preperturbationwindow preperturbationwindow],[0 5],...
        'color','k','LineStyle','--','Linewidth',1);
    set(gca,'XLim',[1 1000+preperturbationwindow],'YLim',[0 5]);
    
    %% calculate features
    % Put results into a main struct
    if mode(TrajectoryStats(idx,8))==1
        mytag = 'A';
    else
        mytag = 'B';
    end
    
    % Time to respond to the perturbation
    fstart = TrajectoryStats(idx,9);
    pstart = TrajectoryStats(idx,11);
    Results.(mytag).ResponseLatency = (fstart - pstart)*2; % in ms
    % Lever Value at time of perturbation trigger
    Results.(mytag).LeverVals = MyLever(:,preperturbationwindow);
    % No. of sniffs before correction
    load(AllSessions(i).name, 'Inhalations');
    load(AllSessions(i).name, 'Exhalations');
%     
%     if strcmp(AllSessions(i).name,'N8_20181021_r0_processed.mat')
%         disp('stop');
%     end
    SniffCounts = [];
    for k = 1:size(MyLever,1)    
        if ~isempty(cell2mat(Inhalations(idx(k))))
            sniffs = cell2mat(Inhalations(idx(k)));
            SniffCounts(k,1) = numel(find((sniffs>=pstart(k))&(sniffs<=fstart(k))));
            if SniffCounts(k,1) == 0
                SniffCounts(k,1) = NaN;
            end
        else
            SniffCounts(k,1) = NaN;
        end 
    end
    Results.(mytag).SniffCounts = SniffCounts;
    
    
end
title(tag);

%end