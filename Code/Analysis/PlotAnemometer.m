load('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior/Calibrations/Anemometer/Calibrations_20180830_r0.mat');

% get motor location
Motor = round(session_data.trace(:,4));
MotorTemp = Motor;
MotorTemp(MotorTemp>-100) = 1;
MotorTemp(MotorTemp<1) = 0;
starts = find(diff([0; MotorTemp])==1);
stops = find(diff([0; MotorTemp])==-1);
starts(end,:) = [];

mycolors = colormap(brewermap([16],'Spectral'));

% chunk up the session into runs

% baseline
MyAnemo = session_data.trace(starts(1):stops(1),6);
MyMotor = Motor(starts(1):stops(1),1);
Baseline = [mean(MyAnemo) std(MyAnemo)];
increment = 5;
for i = 2:size(starts,1)
    MyAnemo = session_data.trace(starts(i):stops(i),6) - Baseline(1);
    MyMotor = Motor(starts(i):stops(i),1);
    count = 0;
    for j = -101:increment:100-increment
        idx = find((MyMotor>j)&(MyMotor<=(j+increment)));
        count = count + 1;
        Flow(i-1,count,:) = [mean(MyAnemo(idx)) std(MyAnemo(idx))];
    end
    
%     MyShadedErrorBar(-101:increment:(100-increment), squeeze(Flow(i-1,:,1)),squeeze(Flow(i-1,:,2)),...
%         mycolors(i-1,:),[],0.5);
%     hold on
end

count = 0;
for j = -101:increment:100-increment
    count = count + 1;
    myflow = [mean(Flow(:,count,1)) std(Flow(:,count,1))];
    line(1+[j j],[myflow(1)+[myflow(2) -myflow(2)]],'color','k','LineWidth',2);
    hold on
    plot(1+j,myflow(1),'ok','MarkerFaceColor','k');
end

set(gca,'TickDir','out');
set(gcf,'renderer','Painters');
cd '/Users/Priyanka/Desktop/LABWORK_II/conferences:meetings/SFN2018/figures';


