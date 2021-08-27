function [MyMean] = Mean_NoNaNs(data,dim)
if nargin<2
    dim = 1;
end
if dim == 2
    data = data';
end
MyMean = [];
for i = 1:size(data,2)
    a = data(:,i);
    MyMean(1,i) = mean(a(~isnan(a)));
    MyMean(2,i) = std(a(~isnan(a)));
    MyMean(3,i) = numel(a(~isnan(a)));
    MyMean(4,i) = MyMean(2,i)/sqrt(MyMean(3,i));
    MyMean(5,i) = median(a(~isnan(a)));
end
end