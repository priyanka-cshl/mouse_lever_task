function SaveLastBehaviorFile(animal_name, useserver)

if nargin<2
    useserver = 1;
end

NIchannels = 14;
num_params = 35;
length_TF = 100;

% filename for writing data
foldername_local = 'C:\Data\Behavior';
foldername_server = '\\grid-hs\albeanu_nlsas_norepl_data\pgupta\Behavior';

% read session data
f = fopen('C:\temp_data_files\log.bin');
% reads up to six hours -- include the time vec and the data
a = fread(f,[NIchannels+1 10800000],'double');
fclose(f);

% read settings log
f = fopen('C:\temp_data_files\settings_log.bin');
b = fread(f,[1 + num_params 10000],'double'); % params vector + timestamp
fclose(f);

% read TF log
f = fopen('C:\temp_data_files\transferfunction_log.bin');
c = fread(f,[(3+length_TF) 10000],'double');
fclose(f);

FileExistChecker = 1;
run_num = 0;

while FileExistChecker
    filename = [foldername_local, filesep, animal_name, filesep, ...
        animal_name, '_', datestr(now, 'yyyymmdd'), ['_r' num2str(run_num) ], '.mat'];
    run_num = run_num + 1;
    if ~exist(fileparts(filename)) %#ok<*EXIST>
        mkdir(fileparts(filename));
    end
    FileExistChecker = exist(filename,'file');
end

[~,file_final_name]=fileparts(filename);
server_file_name = [foldername_server, filesep, animal_name, filesep, file_final_name];
if useserver
    if ~exist(fileparts(server_file_name))
        mkdir(fileparts(server_file_name));
    end
end

% read session settings
load('C:\temp_data_files\session_settings.mat'); % loads variable settings
session_data = mysettings;
session_data.timestamps = a(1,:)';
session_data.trace = a(2:NIchannels+1,:)';
session_data.trace_legend = Connections_list();
session_data.params = b';
session_data.TF = c';

save(filename,'session_data*');
display(['saved to ' filename]);
if useserver
    save(server_file_name,'session_data*');
    display(['saved to ' server_file_name])
end
clear a b c session_data
