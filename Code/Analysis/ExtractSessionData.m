% test script to extract behavior data and replot session
function [MyData, params, TargetZones, FakeTargetZones] = ExtractSessionData(FileName, PIDflag)
    if nargin<2
        PIDflag = 0;
    end
    
    % load the file
    Temp = load(FileName,'session_data');
    if PIDflag
        MyData = Temp.session_data.trace(:,[6 3 7:11]);
    else
        MyData = Temp.session_data.trace(:,[1 3 7:11]);
    end
        
    % add three columns in the beginning - 1 for timestamp and 2 for target zone levels
    % add two columns in the end - for fake target zone levels
    MyData = [Temp.session_data.timestamps Temp.session_data.timestamps...
        Temp.session_data.timestamps MyData Temp.session_data.timestamps Temp.session_data.timestamps];
    
    
    %% clean up params table
    %% HACK - in some versions of the code, params were written to
    %% disc with -ve timestamp before an actual update happened
    % only start with entries that have non-zero timestamps
    Temp.session_data.params(1: find(Temp.session_data.params(:,1)==0,1,'last')-1,:) = [];
    % if timestamps are negative - ignore those
    Temp.session_data.params(find(Temp.session_data.params(:,1)<0),:) = [];
    
    % get target zone values
    for t = 1:size(Temp.session_data.params,1)-1
        f = find((MyData(:,1)>=Temp.session_data.params(t,1)) &...
            (MyData(:,1)<Temp.session_data.params(t+1,1)));
        MyData(f,2) = Temp.session_data.params(t,18);
        MyData(f,3) = Temp.session_data.params(t, 20);
        if Temp.session_data.params(t,29) == 1 % to detect mapping flip perturbations
            MyData(f,11) = 100;
            MyData(f,12) = 100;
        elseif  Temp.session_data.params(t,31) == 1 % offset perturbations
            MyData(f,11) = Temp.session_data.params(t,9);
            MyData(f,12) = Temp.session_data.params(t,9);
        else% fake target zone perturbations
            MyData(f,11) = Temp.session_data.params(t,26);
            MyData(f,12) = Temp.session_data.params(t, 28);
        end
    end
    f = find(MyData(:,1)>=Temp.session_data.params(end,1));
    MyData(f,2) = Temp.session_data.params(end,18);
    MyData(f,3) = Temp.session_data.params(end, 20);
    if Temp.session_data.params(end,29) % to detect mapping flip perturbations
        MyData(f,11) = 100;
        MyData(f,12) = 100;
    elseif  Temp.session_data.params(end,31) == 1 % offset perturbations
        MyData(f,11) = Temp.session_data.params(end,9);
        MyData(f,12) = Temp.session_data.params(end,9);
    else % fake target zone perturbations
        MyData(f,11) = Temp.session_data.params(end,26);
        MyData(f,12) = Temp.session_data.params(end, 28);
    end
    
    % append motor location and,  home sensor column (if available)
    % and fake lim center
    %MyData(:,end+1) = Temp.session_data.trace(:,4); % motor location
    % fix a scaling bug in some versions of the fix speed TF code (used during nov, dec 2017)
    if isequal(mode(Temp.session_data.params(:,21:23)),[14 121 66])
        MyData(:,end+1) = mode(Temp.session_data.params(:,22))*Temp.session_data.trace(:,4)/sum(mode(Temp.session_data.params(:,21:23)));
    else
        MyData(:,end+1) = Temp.session_data.trace(:,4);
    end

    if size(Temp.session_data.trace,2)>11
        MyData(:,end+1) = Temp.session_data.trace(:,12);
    end
    
    % convert trial_ON column to odor IDs
    % column number = 6 in MyData
    for odor = 1:4
        f = find((MyData(:,6)>=odor^2) & (MyData(:,6)<(odor+1)^2));
        MyData(f,6) = odor;
    end
    
    params = Temp.session_data.params;
    TargetZones = unique(params(:,18:20),'rows');
    FakeTargetZones = unique(params(:,26:28),'rows');
    if any(find(params(:,29)))
        FakeTargetZones = [FakeTargetZones; [100 100 100]];
    end
    if any(find(params(:,31)))
        foo = unique(MyData(:,[11]),'rows');
        foo(find(foo==0),:) = [];
        FakeTargetZones = [FakeTargetZones; repmat(foo, 1, 3)];
    end
    % Sanity check
    foo = FakeTargetZones;
    foo(:,2) = foo(:,2) - foo(:,1);
    FakeTargetZones(find((foo(:,2)==0)&(foo(:,1)<20)&(foo(:,1)>0)),:) = [];
    
end