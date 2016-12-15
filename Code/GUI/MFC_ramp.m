function [] = MFC_ramp(handles)
disp('starting up MFCs ... ');
for i = 1:length(handles.MFC_table.Data)
    MFC_values(:,i) = linspace(0,handles.MFC_table.Data(i),10);
end
% 10 steps
x = '.';
for i = 1:10
    outputSingleScan(handles.MFC,MFC_values(i,:));
    pause(5);
    x = [x,'.'];
    disp(x)
end
disp('MFCs ready!');
    