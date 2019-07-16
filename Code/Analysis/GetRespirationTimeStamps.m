function [sniff_stamps] = GetRespirationTimeStamps(RespData, threshold, doplot)

if nargin<2
    threshold = 0.2;
end

if nargin<3
    doplot = 0;
end

% rescale the data
RespData = RespData - median(RespData);

if doplot
    figure;
    plot(1:length(RespData),RespData);
    hold on
    plot(1:length(RespData),0*RespData,'k');
end

[pks,dep,pid,did] = peakdet(RespData,threshold);

sniff_stamps = [];
% do some pruning
for i = 1:numel(pks)-1
    % pks are exhalations
    % is there an inhalation in between, if not, delete this entry
    if any((did>pid(i)) & (did<pid(i+1)))
        f = find((did>pid(i)) & (did<pid(i+1)));
        if numel(f)>1
            all_dips = dep(f);
            [~,m] = min(all_dips);
            sniff_stamps = [sniff_stamps; [pid(i) did(f(m))]];
        else
            sniff_stamps = [sniff_stamps; [pid(i) did(f)]];
        end
    end
end

% detect inhalation starts
for i = 1:size(sniff_stamps,1)
    sniff_stamps(i,3) = -1 + sniff_stamps(i,1) + find(RespData(sniff_stamps(i,1):sniff_stamps(i,2))<=0,1,'first');
    if i < size(sniff_stamps,1)
        sniff_stamps(i,4) = -1 + sniff_stamps(i,2) + find(RespData(sniff_stamps(i,2):sniff_stamps(i+1,1))>=0,1,'first');
    end
        
end

if doplot
    plot(sniff_stamps(:,1),RespData(sniff_stamps(:,1)),'ok');
    plot(sniff_stamps(:,2),RespData(sniff_stamps(:,2)),'or');
    plot(sniff_stamps(:,3),RespData(sniff_stamps(:,3)),'og');
    plot(sniff_stamps(:,4),RespData(sniff_stamps(:,3)),'om');
end

end