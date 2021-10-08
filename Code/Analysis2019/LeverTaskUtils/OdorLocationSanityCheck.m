function [MyData, DataTags] = OdorLocationSanityCheck(MyData, DataTags)
global errorflags; % [digital-analog sample drops, timestamp drops, RE voltage drift, motor slips]

checkflags = [0 0];

MotorCol = find(cellfun(@isempty,regexp(DataTags,'Motor'))==0);
EncoderCol = find(cellfun(@isempty,regexp(DataTags,'Encoder'))==0);

% check that TEENSY analog output had no drift
[coeff,gof] = fit(MyData(:,MotorCol),MyData(:,EncoderCol),'poly1');
checkflags(1) = (gof.rsquare > 0.98);

HomeCol = find(cellfun(@isempty,regexp(DataTags,'HomeSensor'))==0);
foo = MyData(:,MotorCol); 
foo(find(MyData(:,HomeCol)==0)) = NaN;
fooLims = median(foo,'omitnan') + [std(foo,'omitnan') -std(foo,'omitnan')];
checkflags(2) = ~any(abs(fooLims)>4);

% figure;
% scatter(MyData(:,MotorCol),MyData(:,EncoderCol))
% hold on
% scatter(foo,MyData(:,EncoderCol),'r')

if ~any(checkflags)
     disp('Warning: session failed sanity check');
else
    disp('session passed sanity check');
    % delete the Encoder Col and Homesensor column
    MyData(:,[EncoderCol HomeCol]) = [];
    DataTags([EncoderCol HomeCol],:) = [];
end

errorflags(3:4) = checkflags;
end