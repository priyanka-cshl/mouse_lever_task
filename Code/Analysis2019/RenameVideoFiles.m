
% get all Files
AllFiles = dir('*cam*'); % for cam1
for i = 1:size(AllFiles,1)-1
    disp([num2str(i),' of ',num2str(size(AllFiles,1)-1)]);
    [foo] = strsplit(AllFiles(i).name,'cam');
    movefile(AllFiles(i).name,['cam',foo{2}]);
%     NumFrames(i,1) = X.NumFrames;
end


% NumFrames = [];
% for i = 1:size(AllFiles,1)-1
%     X = aviinfo(['camA',num2str(i),'.avi']);
%     NumFrames(i,1) = X.NumFrames;
% end
% AllFiles = dir('*camB*'); % for cam2
% for i = 1:size(AllFiles,1)-1
%     X = aviinfo(['camB',num2str(i),'.avi']);
%     NumFrames(i,2) = X.NumFrames;
% end