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
    case 'Priyanka-PC'
        Paths.Behavior = 'C:\Data\Behavior'; % location on rig computer
    case 'andaman'
        Paths.Behavior = '/mnt/data/Priyanka/behavior'; % location on rig computer
        Paths.Ephys = '/mnt/data/Priyanka';
        Paths.Code = '/opt';
    otherwise
        Paths.Behavior = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % local copy
            Paths.Ephys = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys';
            Paths.Code = '/Users/Priyanka/Desktop/github_local';
        %Paths.Behavior = '//sonas-hs.cshl.edu/Albeanu-Norepl/pgupta/Behavior'; % location on sonas server
end

end