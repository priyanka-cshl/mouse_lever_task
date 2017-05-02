function [StayTimes, TrialStats, M, S] = TimeSpentInZone(LeverTruncated, ZonesToUse, TargetZones, TrialInfo, Params, DoPlot)
global MyFileName;

MinHold = min(Params(:,6));


Scores = zeros(2,numel(ZonesToUse),numel(ZonesToUse));
for t = 1:size(LeverTruncated,1) % each trial    
    for Z = 1:numel(ZonesToUse)
        % Zone LImits
        HighLim = TargetZones(Z,1);
        LowLim = TargetZones(Z,2);
        temp = LeverTruncated(t,:);
        triallength = numel(temp(~isnan(temp)));
        % threshold any points outside target zone limits
        temp(temp>=HighLim) = HighLim;
        temp(temp<=LowLim) = LowLim;
        tempdiff = diff(temp);
        tempdiff(tempdiff~=0)=1;
        % find points of target zone entry and exit
        f = find(diff(tempdiff)~=0)';
        if size(f,1)>1
            if mod(length(f),2)
                f(end+1,:) = find(~isnan(temp),1,'last');
            end
            crosses = [f(1:2:end) f(2:2:end)];
            crosses(:,3) = crosses(:,2) - crosses(:,1);
            % was it a downswing or upswing?
            for i = 1:size(crosses,1)
                x = crosses(i,1); y = x - 9;
                y = max(y,1); % ignore -ve values
                crosses(i,4) = mean(LeverTruncated(t,y:x))>=HighLim;
            end
            StayTimes.(['Zone',num2str(Z)]){t} = {crosses};
            % Fraction of time spent in each zone
            TrialStats.FractionSpent(t,Z) = sum(crosses(:,3))/triallength;
            % Max stay in each Zone
            TrialStats.MaxStay(t,Z) = max(crosses(:,3));
            TrialStats.MaxFractionStay(t,Z) = max(crosses(:,3))/triallength;
        else            
            % Fraction of time spent in each zone
            TrialStats.FractionSpent(t,Z) = 0;
            % Max stay in each Zone
            TrialStats.MaxStay(t,Z) = 0;
            TrialStats.MaxFractionStay(t,Z) = 0;
        end
    end
    which_row = find(ZonesToUse==TrialInfo.TargetZoneType(t));
    [MaxHold,which_col] = max(TrialStats.MaxStay(t,:));
    if MaxHold>=MinHold-50
        Scores(1,which_row,which_col) = Scores(1,which_row,which_col) + 1;
        [~,which_col] = max(TrialStats.MaxFractionStay(t,:));
        Scores(2,which_row,which_col) = Scores(2,which_row,which_col) + 1;
    end
end

for x = 1:3
    Scores(1,x,:) = Scores(1,x,:)/sum(Scores(1,x,:));
    Scores(2,x,:) = Scores(2,x,:)/sum(Scores(2,x,:));
end

for Z1 = 1:numel(ZonesToUse)
    for Z2 = 1:numel(ZonesToUse)
        M(1,Z1,Z2) = median(TrialStats.FractionSpent(find(TrialInfo.TargetZoneType==ZonesToUse(Z1)),Z2));
        S(1,Z1,Z2) = std(TrialStats.FractionSpent(find(TrialInfo.TargetZoneType==ZonesToUse(Z1)),Z2));
        M(2,Z1,Z2) = median(TrialStats.MaxStay(find(TrialInfo.TargetZoneType==ZonesToUse(Z1)),Z2));
        S(2,Z1,Z2) = std(TrialStats.MaxStay(find(TrialInfo.TargetZoneType==ZonesToUse(Z1)),Z2));
        M(3,Z1,Z2) = median(TrialStats.MaxFractionStay(find(TrialInfo.TargetZoneType==ZonesToUse(Z1)),Z2));
        S(3,Z1,Z2) = std(TrialStats.MaxFractionStay(find(TrialInfo.TargetZoneType==ZonesToUse(Z1)),Z2));
    end
end

%% Make plots
if DoPlot
    MyTitle = {'Time spent', 'Longest stay (ms)', 'Longest Fraction Spent'};

    figure('name',[char(MyFileName),'StayTimes']);
    for x = 1:3
        subplot(1,3,x); hold on
        ax = gca;
        ax.Title.String =  char(MyTitle(x));
        for y = 1:3
            for z = 1:3
                cmat = [0 0 0];
                cmat(z) = 1;
                errorbar(y+0.2*z,M(x,y,z),S(x,y,z),'color',cmat/2);
                %bar(y+0.2*z,M(x,y,z),0.1,'FaceColor','none','EdgeColor',cmat/2);
                if y == z
                    bar(y+0.2*z,M(x,y,z),0.15,'FaceColor',cmat/2,'EdgeColor','k', 'Linewidth',3);
                else
                    bar(y+0.2*z,M(x,y,z),0.15,'FaceColor',cmat/2,'EdgeColor','none');
                end
            end
            
        end
    end
    
    figure('name',[char(MyFileName),'Scores']);
    for x = 1:3
        subplot(1,2,1);
        imagesc(squeeze(Scores(1,:,:)));
        subplot(1,2,2);
        imagesc(squeeze(Scores(2,:,:)));
    end

end

end

