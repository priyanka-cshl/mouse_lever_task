function [DataRoot] = WhichComputer()

% read computer name
[~,computername] = system('hostname');
computername = deblank(computername);

switch computername
    case 'priyanka-gupta.cshl.edu'
        DataRoot = '/Volumes/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
    case {'priyanka-gupta.home', 'priyanka-gupta.local'}
        if exist('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior','dir')
            DataRoot = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % local copy
        else
            DataRoot = '/Volumes/Albeanu-Norepl/pgupta/Behavior';
        end
    case 'Priyanka-PC'
        DataRoot = 'C:\Data\Behavior'; % location on rig computer
    case 'andaman'
        DataRoot = '/mnt/data/Priyanka/behavior'; % location on rig computer
    otherwise
        DataRoot = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
end

end