function [myephysdir] = WhereSpikeFile(BehaviorFile)
foo = strsplit(BehaviorFile,'_');
mousename = char(foo(1));
date = char(foo(2));
datetoken = [date(1:4),'-',date(5:6),'-',date(7:8)];
root = ['/mnt/data/Priyanka/',mousename,'/'];
myfolders = dir ([root,'/',datetoken,'*']);

if size(myfolders,1) == 0
    myephysdir = [];
elseif size(myfolders,1) == 1
    myephysdir = myfolders.name;
    myephysdir = fullfile(root,myephysdir);
else
    sessionname = char(foo(3));
    session_num = str2num(sessionname(2));
    myephysdir = myfolders(session_num+1).name;
    myephysdir = fullfile(root,myephysdir);
end

end