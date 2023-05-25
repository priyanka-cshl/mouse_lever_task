% function [] = FeedbackPausePerturbation()


% load the trajectories
load(AllSessions(i).name, 'Trajectories');

MyZones = (unique(TrajectoryStats(find(TrajectoryStats(:,7)==perturbationID),6)));
TargetZones = [1:0.25:3.75];

% for plotting
foo = colormap(brewermap([9],'YlOrRd'));
if numel(MyZones)==3
    mycolors = foo([9 6 4],:);
else
    mycolors = foo;
end

if perturbationID == 9
    preperturbationwindow = 0;
else
    preperturbationwindow = 50;
end
figure('Name',AllSessions(i).name);
subplot(1,4,1); hold on
subplot(1,4,2); hold on
subplot(1,4,3); hold on
subplot(1,4,4); hold on

for j = 1:numel(MyZones) % for each offset
    idx = find((TrajectoryStats(:,7)==perturbationID)&(TrajectoryStats(:,6)==MyZones(j)));
    if perturbationID == 10
        pstart = TrajectoryStats(idx,11) - preperturbationwindow; % time at which feedback was turned off
        pstop = mode(TrajectoryStats(idx,9) - TrajectoryStats(idx,11));
    end
    if perturbationID == 9
        pstop = mode(TrajectoryStats(idx,9)); % time at which feedback was turned off
        pstart = 0*ones(numel(idx),1);
        %pstop = mode(TrajectoryStats(idx,9) - TrajectoryStats(idx,11));
    end
    
    % get relevant trials
    MyLever = Trajectories.Lever(idx,:);
    
    % chop off unnecessary samples from the beginning of the trial
    subplot(1,4,1);
    for k = 1:size(MyLever,1)
        mytrace = circshift(MyLever(k,:),-pstart(k));
        mytrace(1,end-pstart(k):end) = NaN;
        MyLever(k,:) = mytrace;
        plot(1:length(mytrace),mytrace,'color',mycolors(j,:));
    end
    line([1 length(mytrace)],[TargetZones(MyZones(j)) TargetZones(MyZones(j))],...
        'color','k','LineStyle','--','Linewidth',1);
    line([preperturbationwindow preperturbationwindow],[0 5],...
        'color','k','LineStyle','--','Linewidth',1);
    line(pstop+[preperturbationwindow preperturbationwindow],[0 5],...
        'color','k','LineStyle','--','Linewidth',1);
    set(gca,'XLim',[1 1000+preperturbationwindow],'YLim',[0 5]);

    % plot the average trace as well
    subplot(1,4,2);
    MyShadedErrorBar(1:size(MyLever,2),nanmean(MyLever,1),...
        std(MyLever,'omitnan')/sqrt(numel(idx)),...
        mycolors(j,:),[],0.7);
    line([1 length(mytrace)],[TargetZones(MyZones(j)) TargetZones(MyZones(j))],...
        'color','k','LineStyle','--','Linewidth',1);
    line([preperturbationwindow preperturbationwindow],[0 5],...
        'color','k','LineStyle','--','Linewidth',1);
    line(pstop+[preperturbationwindow preperturbationwindow],[0 5],...
        'color','k','LineStyle','--','Linewidth',1);
    set(gca,'XLim',[1 1000+preperturbationwindow],'YLim',[0 5]);
    
    % plot a histogram of the trajectories in the feedback halt period
    foo = MyLever(:,preperturbationwindow+(1:pstop));
    H = hist(foo(:),[0:0.2:5]);
    subplot(1,4,3); 
    area([0:0.2:5],H/max(H),'FaceColor',mycolors(j,:),'FaceAlpha',0.7); %,'EdgeColor','none');
    set(gca,'YLim',[0 1.25],'XDir','reverse');
    
    % same but for only first half of the halt period
    % plot a histogram of the trajectories in the first half of the feedback halt period
    foo = MyLever(:,preperturbationwindow+(1:floor(pstop/2)));
    H = hist(foo(:),[0:0.2:5]);
    subplot(1,4,4); 
    area([0:0.2:5],H/max(H),'FaceColor',mycolors(j,:),'FaceAlpha',0.7); %,'EdgeColor','none');
    set(gca,'YLim',[0 1.25],'XDir','reverse');
end

subplot(1,4,3); camroll(-90);
subplot(1,4,4); camroll(-90);



