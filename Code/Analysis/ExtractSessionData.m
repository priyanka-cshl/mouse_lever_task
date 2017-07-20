% test script to extract behavior data and replot session
function [MyData, params, TargetZones, FakeTargetZones] = ExtractSessionData(FileName)
    % load the file
    Temp = load(FileName,'session_data');
    MyData = Temp.session_data.trace(:,[1 3 7:11]);
        
    % add three columns in the beginning - 1 for timestamp and 2 for target zone levels
    % add two columns in the end - for fake target zone levels
    MyData = [Temp.session_data.timestamps Temp.session_data.timestamps...
        Temp.session_data.timestamps MyData Temp.session_data.timestamps Temp.session_data.timestamps];
    
    % get target zone values
    for t = 1:size(Temp.session_data.params,1)-1
        f = find((MyData(:,1)>=Temp.session_data.params(t,1)) &...
            (MyData(:,1)<Temp.session_data.params(t+1,1)));
        MyData(f,2) = Temp.session_data.params(t,18);
        MyData(f,3) = Temp.session_data.params(t, 20);
        MyData(f,11) = Temp.session_data.params(t,26);
        MyData(f,12) = Temp.session_data.params(t, 28);
    end
    f = find(MyData(:,1)>=Temp.session_data.params(end,1));
    MyData(f,2) = Temp.session_data.params(end,18);
    MyData(f,3) = Temp.session_data.params(end, 20);
    MyData(f,11) = Temp.session_data.params(end,26);
    MyData(f,12) = Temp.session_data.params(end, 28);
    
    % append motor location and,  home sensor column (if available)
    % and fake lim center
    MyData(:,end+1) = Temp.session_data.trace(:,4);
    if size(Temp.session_data.trace,2)>11
        MyData(:,end+1) = Temp.session_data.trace(:,12);
    end
    
    % convert trial_ON column to odor IDs
    % column number = 6 in MyData
    for odor = 1:3
        f = find((MyData(:,6)>=odor^2) & (MyData(:,6)<(odor+1)^2));
        MyData(f,6) = odor;
    end
    
    params = Temp.session_data.params;
    TargetZones = unique(params(:,18:20),'rows');
    FakeTargetZones = unique(params(:,26:28),'rows');
end