Results = [];

% load the trajectories
load(AllSessions(i).name, 'Trajectories');

MyGains = (unique(TrajectoryStats(find(TrajectoryStats(:,7)==perturbationID),8)));
TargetZonesA = [2 11];

% if isempty(strfind(AllSessions(i).name,'concatenated'))
%     return;
% end

% for plotting
foo = colormap(brewermap([9],'YlOrRd'));
mycolors = foo([9 6 4],:);

figure('Name',AllSessions(i).name);
subplot(2,2,1); hold on
subplot(2,2,2); hold on
subplot(2,2,3); hold on
subplot(2,2,4); hold on

for j = 1:numel(MyGains)
    % get all perturbed trials
    idx = find((TrajectoryStats(:,7)==perturbationID)&(TrajectoryStats(:,8)==MyGains(j)));
    whichodor = mode(TrajectoryStats(idx,10));
    whichtargetzone = mode(TrajectoryStats(idx,6));
    
    % get relevant trials
    MyLever = Trajectories.Lever(idx,:);
    % plot single trials
    subplot(2,2,1 + 2*(MyGains(j)>1));
    for k = 1:size(MyLever,1)
        plot(1:size(MyLever,2),MyLever(k,:),'color',mycolors(2,:));
    end
    % plot averages
    subplot(2,2,2 + 2*(MyGains(j)>1));
    MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
        std(MyLever,'omitnan')/sqrt(numel(idx)),...
        mycolors(2,:),[],0.7);
    
    % plot the trials which share the same odor start location
    idx = find((TrajectoryStats(:,7)==0)&...
            (TrajectoryStats(:,6)==TargetZonesA(j))&...
            (TrajectoryStats(:,10)==whichodor));
    
    % get relevant trials
    MyLever = Trajectories.Lever(idx,:);
    % plot single trials
    subplot(2,2,1 + 2*(MyGains(j)>1));
    for k = 1:size(MyLever,1)
        plot(1:size(MyLever,2),MyLever(k,:),'color',mycolors(1,:));
    end
    % plot averages
    subplot(2,2,2 + 2*(MyGains(j)>1));
    MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
        std(MyLever,'omitnan')/sqrt(numel(idx)),...
        mycolors(1,:),[],0.7);
        
    
    % plot the trials which share the same targetzone location
    if whichodor == 3
        idx = find((TrajectoryStats(:,7)==0)&...
            (TrajectoryStats(:,6)==whichtargetzone)&...
            (TrajectoryStats(:,10)==whichodor));
    else
        idx = find((TrajectoryStats(:,7)==0)&...
            (TrajectoryStats(:,6)==whichtargetzone)&...
            (TrajectoryStats(:,10)==(3-whichodor)));
    end
    
    % get relevant trials
    MyLever = Trajectories.Lever(idx,:);
    % plot single trials
    subplot(2,2,1 + 2*(MyGains(j)>1));
    for k = 1:size(MyLever,1)
        plot(1:size(MyLever,2),MyLever(k,:),'color',mycolors(3,:));
    end
    set(gca,'YLim',[0 5],'XLim',[0 1000]);
    
    % plot averages
    subplot(2,2,2 + 2*(MyGains(j)>1));
    MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
        std(MyLever,'omitnan')/sqrt(numel(idx)),...
        mycolors(3,:),[],0.7);
    set(gca,'YLim',[0 5],'XLim',[0 1000]);
end

