
% get all Files
AllFiles = dir('camA*'); % for cam1
NumFrames = [];
for i = 1:size(AllFiles,1)-1
    X = aviinfo(['camA',num2str(i),'.avi']);
    NumFrames(i,1) = X.NumFrames;
end
AllFiles = dir('camB*'); % for cam2
for i = 1:size(AllFiles,1)-1
    X = aviinfo(['camB',num2str(i),'.avi']);
    NumFrames(i,2) = X.NumFrames;
end