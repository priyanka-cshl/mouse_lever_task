function [] = PlotPerturbationEffect()
load('/Users/Priyanka/Desktop/temp/SuccessRatePerturbations.mat');
% loads Compiled
% Convert trial counts to Success Rates
temp = Compiled;
for i = 1:size(Compiled,1)
    temp(i,1) = sum(Compiled(i,3:2:8));
    temp(i,2) = sum(Compiled(i,4:2:8));
    for j = 1:4
        if mod(i,2)==0
            Rates_A(i/2,j) = temp(i,-1+j*2)/temp(i,2*j);
        else
            Rates_B((i+1)/2,j) = temp(i,-1+j*2)/temp(i,2*j);
        end
    end
end

% three animals
AnimalID = [8 14 11];
figure;
for A = 1:3
    subplot(1,3,A); hold on
    % plot all target zones
    f = find(Compiled(1:2:size(Compiled,1),1)==AnimalID(A));
    for z = 1:4
        x = [z-0.4 z-0.4 z+0.4 z+0.4];
        y = [0 1 1 0];
        fill( [x], [y], ZoneColors(z-1), 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        % plot all success rates - each day
        plot([z-0.2 z+0.2],[Rates_B(f,z) Rates_A(f,z)],'k');
        plot(z-0.2,Rates_B(f,z),'ok','MarkerFaceColor','k');
        plot(z+0.2,Rates_A(f,z),'ok','MarkerFaceColor',ZoneColors(z-1));
    end
        
    axis square;
    set(gca,'XLim', [0 5],'XTick',[1:4], 'YLim',[0 1],'YTick',[0 0.5 1],'TickDir','out','Box', 'on', 'Linewidth', 2, 'FontSize', 10, 'FontWeight', 'bold');
end
end