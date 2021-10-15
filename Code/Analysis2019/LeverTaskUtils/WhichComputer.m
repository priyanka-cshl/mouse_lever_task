function [Paths] = WhichComputer()

% read computer name
[~,computername] = system('hostname');
computername = deblank(computername);

switch computername
    case {'priyanka-gupta.cshl.edu', '*.cshl.edu'}
        Paths.Behavior = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % local copy
            Paths.Ephys = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys';
            Paths.Code = '/Users/Priyanka/Desktop/github_local';
    case {'priyanka-gupta.home', 'priyanka-gupta.local','priyanka-gupta.fios-router.home'}
        if exist('/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior','dir')
            Paths.Behavior = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % local copy
            Paths.Ephys = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys';
            Paths.Code = '/Users/Priyanka/Desktop/github_local';
        else
            Paths.Behavior = '/Volumes/Albeanu-Norepl/pgupta/Behavior';
        end
    case 'maddalena'
        Paths.Behavior = '/mnt/data/Priyanka/Behavior'; % local copy
        Paths.Ephys = '/mnt/data/Priyanka/Ephys';
        Paths.Code = '/opt';
    case 'Priyanka-PC'
        Paths.Behavior = 'C:\Data\Behavior'; % location on rig computer
    case 'andaman'
        Paths.Behavior = '/mnt/data/Priyanka/behavior'; % location on rig computer
        %Paths.Ephys = '/mnt/data/Priyanka';
        Paths.Ephys = '/mnt/grid-hs/pgupta/EphysData'; % for PCX batch
        Paths.Code = '/opt';
    case 'Justine'
        Paths.Behavior = 'C:\Data\Behavior';
        Paths.Ephys = '/mnt/data/Priyanka';
        Paths.Code = 'C:\Users\Rig\Desktop\Code';
    case 'PRIYANKA-HP'
        Paths.Behavior = 'C:\Data\Behavior';
        Paths.Ephys = '/mnt/data/Priyanka';
        Paths.Code = 'C:\Users\pgupta\Desktop\Git_Local';
    otherwise
        Paths.Behavior = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % local copy
            Paths.Ephys = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys';
            Paths.Code = '/Users/Priyanka/Desktop/github_local';
        %Paths.Behavior = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
end

end