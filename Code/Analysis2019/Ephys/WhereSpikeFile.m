function [myephysdir] = WhereSpikeFile(BehaviorFile)
foo = strsplit(BehaviorFile,'_');
mousename = char(foo(1));
date = char(foo(2));
datetoken = [date(1:4),'-',date(5:6),'-',date(7:8)];
root = ['/mnt/data/Priyanka/',mousename,'/'];
myfolders = dir ([root,'/',datetoken,'*']);

if size(myfolders.name,1) == 1
    myephysdir = myfolders.name;
else
    sessionname = char(foo(3));
    session_num = str2num(sessionname(2));
    myephysdir = myfolders(session_num+1).name;
end

myephysdir = fullfile(root,myephysdir);
end