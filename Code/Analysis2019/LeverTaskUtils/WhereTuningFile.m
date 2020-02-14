function [TuningFile] = WhereTuningFile(FilePaths,BehaviorFile)
foo = strsplit(BehaviorFile,'_');
sessiontag = strsplit(char(foo(3)),'.');
sessionnum = char(sessiontag(1));
TuningFile = [char(foo(1)),'_',char(foo(2)),'_o',sessionnum(2:end),'.mat'];
if exist(fullfile(FilePaths,TuningFile),'file')
    TuningFile = fullfile(FilePaths,TuningFile);
else
    TuningFile = [];
end
end