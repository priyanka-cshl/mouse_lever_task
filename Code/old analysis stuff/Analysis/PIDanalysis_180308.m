
% PID data in DataOut
load('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/PID03/compiled3.mat');

% 3 odors, PID centered, PID left, PID right
Idx = [1 5 10; 2 6 9; 3 7 8];

for i = 3 % odors
    for t = 1:5 % trialtypes
        % get traces for center left and right conditions
        foo = DataOut(Idx(i,1)).PID(t:5:50,:);
        % subtract baseline - first 50 ms i.e. 25 samples
        baseline = mean(mean(foo(:,1:25)));
        foo = foo - baseline;
        foo = foo/max(foo(:));
        C.PID = foo;
        C.Motor = DataOut(Idx(i,1)).Motor(t:5:50,:);
        C.Lever = DataOut(Idx(i,1)).Lever(t:5:50,:);
        C.Motor = DataOut(Idx(i,1)).Motor(t:5:50,:);
        
        % make InTZone vectors
        staytimes = cell2mat(DataOut(Idx(i,1)).TrialInfo.StayTime(t));
        staytimestarts = cell2mat(DataOut(Idx(i,1)).TrialInfo.StayTimeStart(t));
        f = find(staytimes<=10);
        staytimes(f,:) = [];
        staytimestarts(f,:) = [];
        InTZone = zeros(1,max(staytimestarts(end)+staytimes(end), size(C.PID,2)));
        for x = 1:numel(staytimestarts)
            InTZone(staytimestarts(x):staytimestarts(x)+staytimes(x)-1) = 1;
        end
        
        tzones = DataOut(Idx(i,1)).TargetZones(DataOut(Idx(i,1)).TrialInfo.TargetZoneType(1:5),1:3);
        
        foo = DataOut(Idx(i,2)).PID(t:5:50,:);
        % subtract baseline - first 50 ms i.e. 25 samples
        baseline = mean(mean(foo(:,1:25)));
        foo = foo - baseline;
        foo = foo/max(foo(:));
        L.PID = foo;
        L.Motor = DataOut(Idx(i,2)).Motor(t:5:50,:);
        
        foo = DataOut(Idx(i,3)).PID(t:5:50,:);
        % subtract baseline - first 50 ms i.e. 25 samples
        baseline = mean(mean(foo(:,1:25)));
        foo = foo - baseline;
        foo = foo/max(foo(:));
        R.PID = foo;
        R.Motor = DataOut(Idx(i,3)).Motor(t:5:50,:);
        
        
        % make them all the same size
        s = min([size(C.PID,2) size(L.PID,2) size(R.PID,2)]);
        C.PID(:,s-1:end) = [];
        R.PID(:,s-1:end) = [];
        L.PID(:,s-1:end) = [];
        InTZone(:,s-1:end) = [];
        
        figure(i);
        % plot lever 
        subplot(3,5,t);
        plot(C.Lever','r'); 
        hold on
        plot(InTZone*5,':k');
        % Plot the Target zone
        myzone = [ tzones(t,[1 3]) tzones(t,[3 1]) ];
        fill( [0 0 size(C.Motor,2) size(C.Motor,2)], myzone, [1 1 0],'FaceAlpha',0.2, 'EdgeColor', 'none');
        set(gca,'XLim', [0 size(C.Motor,2)],'YLim', [0 5],'TickDir','out');
        
        % plot Motor locations
        subplot(3,5,5+t);
        plot(C.Motor','r');
        hold on
        plot(-50+InTZone*170,':k');
        line([0 size(C.Motor,2)],[17 17],'color','k'); line([0 size(C.Motor,2)],[-17 -17],'color','k');
        set(gca,'XLim', [0 size(C.Motor,2)],'YLim', [-50 120],'TickDir','out');
        
        % plot PID centered
        subplot(3,5,10+t);
        %plot(C.PID','k'); 
        MyShadedErrorBar(1:size(C.PID,2),mean(C.PID,1),std(C.PID),'k',[],0.5);
        hold on
        plot(InTZone,':r');
        %line([0 size(C.Motor,2)],[17 17],'color','k'); line([0 size(C.Motor,2)],[-17 -17],'color','k');
        set(gca,'XLim', [0 size(C.Motor,2)],'YLim', [-0.1 1.1],'TickDir','out');
        
        
%         subplot(3,5,10+t);
%         plot(L.PID','b'); 
%         MyShadedErrorBar(1:size(L.PID,2),mean(L.PID,1),std(L.PID),'b',[],0.5);
%         hold on
%         MyShadedErrorBar(1:size(R.PID,2),mean(R.PID,1),std(R.PID),'r',[],0.5);
%         plot(abs(mean(L.PID,1)-mean(R.PID,1)),'k');
%         %line([0 size(C.Motor,2)],[17 17],'color','k'); line([0 size(C.Motor,2)],[-17 -17],'color','k');
%         set(gca,'XLim', [0 size(C.Motor,2)],'YLim', [-0.1 1.1]);
%         plot(InTZone,':k');
    end
end