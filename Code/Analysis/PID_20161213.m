% script to plot PID/Anemometer data for mouse-lever-task

%DataRoot = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
% load testmouse_20161212_r8.mat
% get session files for analysis
DataRoot = '/Users/Priyanka/Desktop';
[FileNames,FilePaths] = uigetfile('.mat','choose one or more session files','MultiSelect','on',DataRoot);
if ~iscell(FileNames)
    temp = FileNames;
    clear FileNames
    FileNames{1} = temp;
    clear temp
end

% get MouseName
MyFileParts = regexp(FilePaths(1:end-1),'\','split');
MouseName = MyFileParts{end};
which_column = 3;

for i = 1:size(FileNames,2)
    % load the file
    Data.(['session',num2str(i)]) = load(fullfile(FilePaths,FileNames{i}),'session_data');
    Data.(['session',num2str(i)]).session_data.path = fullfile(FilePaths,FileNames{i});
    
    % split into sessions of TF update
    for j = 1:size(Data.(['session',num2str(i)]).session_data.TF,1)-1
        t1 = Data.(['session',num2str(i)]).session_data.TF(j,1); % start of session
        t2 = Data.(['session',num2str(i)]).session_data.TF(j+1,1); % end of session
        t = t1 + Data.session1.session_data.TF(j,2)/1000;
        % split into chunks corresponding to each new location
        %row = 0; col = 0;
        count = 0;
        while (t < t2)
            count = count + 1;
            idx1 = find(Data.(['session',num2str(i)]).session_data.timestamps-t1>=0,1);
            idx2 = find(Data.(['session',num2str(i)]).session_data.timestamps-t>=0,1);
            chunks(count,:) = [mean(Data.session1.session_data.trace(idx1:idx2,which_column)) mean(Data.session1.session_data.trace(idx1:idx2,which_column+1)) std(Data.session1.session_data.trace(idx1:idx2,which_column))];
            t1 = t;
            t = t1 + Data.session1.session_data.TF(j,2)/1000;
        end
        % reshape into unique sequence runs
        count1 = 0;
        MyData = [];
        for k = Data.session1.session_data.TF(j,3):Data.session1.session_data.TF(j,3):count
            count1 = count1+1;
            MyData(count1,:,:) = chunks(k-Data.session1.session_data.TF(j,3)+1:k,:);
        end
        AllData{j} = MyData;
    end
    
end

for i = 1:10, subplot(3,4,i); plot(Data.session1.session_data.TF(i,3+(1:Data.session1.session_data.TF(i,3))),squeeze(AllData{i}(:,:,2)),'.'); end

