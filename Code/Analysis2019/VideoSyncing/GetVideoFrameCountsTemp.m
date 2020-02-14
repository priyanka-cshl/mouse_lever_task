
% get all Files
AllFiles = dir('camA*'); % for cam1
NumFrames = [];
j = 35;
for i = 1:size(AllFiles,1)
    disp([num2str(i),' of ',num2str(size(AllFiles,1))]);
    movefile(['camA',num2str(i+j),'.avi'],['camA',num2str(i),'.avi']);
end
AllFiles = dir('camB*'); % for cam2
for i = 1:size(AllFiles,1)
    disp([num2str(i),' of ',num2str(size(AllFiles,1))]);
    movefile(['camB',num2str(i+j),'.avi'],['camB',num2str(i),'.avi']);
end