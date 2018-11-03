function [sniff_stamps] = GetRespirationTimeStamps(RespData, threshold)

if nargin<2
    threshold = 0.2;
end
% rescale the data
RespData = RespData - median(RespData);

figure;
plot(1:length(RespData),RespData); 
hold on
plot(1:length(RespData),0*RespData,'k');
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
plot(sniff_stamps(:,1),RespData(sniff_stamps(:,1)),'ok');
plot(sniff_stamps(:,2),RespData(sniff_stamps(:,2)),'or');

end