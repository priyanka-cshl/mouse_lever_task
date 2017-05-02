function [] = ParameterizeTrajectories(LeverTruncated,TrialInfo, ZonesToUse, TargetZones)
    % plot all (or many) trajectories
    % separate failures and rewards
    
    % Align them to crossing of Trigger ON = ~4.8V
    LeverReAligned = []; idx = [];
    for i = 1:size(LeverTruncated,1) % each trial
        temp = LeverTruncated(i,:);
        t = find(temp<4.75, 1);
        if ~isempty(t)
            temp = [temp(t:end) NaN*ones(1,t-1)];
            LeverReAligned = [LeverReAligned; temp];
            idx = [idx; i];
        end
    end
    
%     % how many subplots
%     figure;
%     for i = 1:min(max(idx),60); 
%         subplot(6,10,i); 
%         colormat = [0 0 0]; 
%         colormat(find(ZonesToUse==TrialInfo.TargetZoneType(idx(i)))) = 1; 
%         plot(LeverReAligned(i,:),'color',colormat); 
%         set(gca,'YLim',[0 5]);
%         mylim = get(gca,'XLim');
%         line(mylim, TargetZones(TrialInfo.TargetZoneType(idx(i)),[1 1]) ,'color','k','LineStyle',':');
%         line(mylim, TargetZones(TrialInfo.TargetZoneType(idx(i)),[2 2]) ,'color','k','LineStyle',':');
%         if TrialInfo.Success(i); 
%             set(gca,'Box','off'); 
%         end; 
%     end
    
    % sort trajectories by zones and separate successes, failures, and
    % perturbations.
    myfakezone = cell2mat(cellfun(@(x) max([x 0]), TrialInfo.FakeZone, 'UniformOutput', false))';
    fig_num = get(gcf,'Number');
    figure(fig_num+1);
    mylim = [0 size(LeverReAligned,2)];
    mylim(1) = -0.05*mylim(2);
    mylim(2) = mylim(2) + abs(mylim(1));
    
    TrajectoriesSummarized = [];
    
    for Z = 1:numel(ZonesToUse)
        all_trials = intersect(idx,find(TrialInfo.TargetZoneType==ZonesToUse(Z)));
        all_trials = intersect(all_trials, find(myfakezone==0));
        successes = intersect(all_trials, find(TrialInfo.Success==1));
        failures = intersect(all_trials, find(TrialInfo.Success==0));
        all_trials = intersect(idx,find(TrialInfo.TargetZoneType==ZonesToUse(Z)));
        perturbed = intersect(all_trials, find(myfakezone>0));
        
        
        % separate plots for averages and all trials
        for M = 1:2
            for i = 1:3
                H = figure(fig_num+M);
                h = subplot(3,numel(ZonesToUse),Z+3*(i-1)); hold on
                h.LineWidth = 2;
                h.Box = 'on';
                h.YTick = [];
                % plot target zones
                for j = 1:numel(ZonesToUse)
                    x = [mylim(1) mylim(1) mylim(2) mylim(2)];
                    y = [ TargetZones(ZonesToUse(j),[1 2]) TargetZones(ZonesToUse(j),[2 1]) ];
                    fill( [x], [y], ZoneColors(ZonesToUse(j)), 'FaceAlpha', 0.4, 'EdgeColor', 'none');
                    % demarcate actual target zone
                    if j == Z
                        rectangle('Position',...
                            [mylim(1), TargetZones(ZonesToUse(j),2), ...
                            abs(mylim(1)), diff(TargetZones(ZonesToUse(j),[2 1]))],...
                            'FaceColor','k','EdgeColor','none');
                    end
                end
                switch i
                    case 1
                        switch M
                            case 1
                                MyTrace = Mean_NoNaNs(LeverReAligned(successes,:));
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'b',[],0.5);
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(5,:),MyTrace(4,:),'r',[],0.5);
                                plot(LeverReAligned(successes,:)','k','LineWidth',0.25);
                                TrajectoriesSummarized{i,Z} = MyTrace;
                            case 2
                                MyTrace = Mean_NoNaNs(LeverReAligned(successes,:));
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'k',[],0.5);
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(5,:),MyTrace(4,:),'r',[],0.5);
                        end
                        h.YColor = 'k';
                        h.XColor = 'k';
                    case 2
                        switch M
                            case 1
                                MyTrace = Mean_NoNaNs(LeverReAligned(failures,:));
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'b',[],0.5);
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(5,:),MyTrace(4,:),'r',[],0.5);
                                plot(LeverReAligned(failures,:)','k','LineWidth',0.25);
                                TrajectoriesSummarized{i,Z} = MyTrace;
                            case 2
                                MyTrace = Mean_NoNaNs(LeverReAligned(failures,:));
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'k',[],0.5);
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(5,:),MyTrace(4,:),'r',[],0.5);
                        end
                        h.YColor = 'r';
                        h.XColor = 'r';
                    case 3
                        switch M
                            case 1
                                MyTrace = Mean_NoNaNs(LeverReAligned(perturbed,:));
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'b',[],0.5);
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(5,:),MyTrace(4,:),'r',[],0.5);
                                plot(LeverReAligned(perturbed,:)','k','LineWidth',0.25);
                                TrajectoriesSummarized{i,Z} = MyTrace;
                            case 2
                                MyTrace = Mean_NoNaNs(LeverReAligned(perturbed,:));
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(1,:),MyTrace(4,:),'k',[],0.5);
                                MyShadedErrorBar(1:size(MyTrace,2),MyTrace(5,:),MyTrace(4,:),'r',[],0.5);
                        end
                        h.YColor = 'b';
                        h.XColor = 'b';
                end
                set(gca,'YLim',[0 5],'XLim',mylim);
            end
        end
    end
    
% calculate correlations
% use min trial length 
triallength = size(TrajectoriesSummarized{1}(1,:),2);
for i = 1:3
    for j = 1:3
        triallength = min(triallength, numel(find(~isnan(TrajectoriesSummarized{i,j}(5,:)))));
    end
end

for i = 1:3
    for j = 1:3
        R = corrcoef(TrajectoriesSummarized{1,i}(5,1:triallength),TrajectoriesSummarized{3,j}(5,1:triallength));
        corrs(i,j) = R(1,2);
    end
end
    
end