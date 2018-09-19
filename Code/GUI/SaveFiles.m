% --- Executes on button press in SaveFile.
function SaveFiles(animal)
% filename for writing data
animal_name = char(animal);
foldername_local = char('C:\Data\Behavior');
foldername_server = char('\\grid-hs\albeanu_nlsas_norepl_data\pgupta\Behavior');
    
% read session data
f = fopen('C:\temp_data_files\log.bin');
% reads up to six hours -- include the time vec and the data
num_channels = size(Connections_list(),2);
a = fread(f,[num_channels+1 10800000],'double');
fclose(f);
    
% read settings log
f = fopen('C:\temp_data_files\settings_log.bin');
num_params = 14+16;
b = fread(f,[1 + num_params 10000],'double'); % params vector + timestamp
fclose(f);
    
% read TF log
f = fopen('C:\temp_data_files\transferfunction_log.bin');
c = fread(f,[(3+100) 10000],'double');
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
handles.file_final_name=file_final_name;
server_file_name=[foldername_server,filesep,animal_name,filesep,file_final_name];
if ~exist(fileparts(server_file_name))
    mkdir(fileparts(server_file_name));
end

% read session settings
load('C:\temp_data_files\session_settings.mat'); % loads variable settings
session_data = mysettings;
session_data.timestamps = a(1,:)';
session_data.trace = a(2:end,:)';
session_data.trace_legend = Connections_list();
session_data.params = b';
session_data.TF = c';

save(filename,'session_data*');
save(server_file_name,'session_data*');
clear a b c session_data
display(['saved to ' filename])
display(['saved to ' server_file_name])
