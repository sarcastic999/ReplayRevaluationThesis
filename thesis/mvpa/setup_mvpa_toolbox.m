function setup_mvpa_toolbox()
    if (not(exist('init_subj')))
        oldpwd = pwd;
        if strcmp(getenv('OS'),'Linux') == 1 % rondo
            cd '/usr/people/erhee/princeton-mvpa-toolbox-read-only';
            mvpa_add_paths;
            addpath(genpath('/usr/people/erhee/spm12/'))
        elseif strcmp(getenv('OS'),'Windows_NT') == 1 % asus
            cd 'G:/princeton-mvpa-toolbox-read-only';
            mvpa_add_paths;
            addpath(genpath('G:/spm12/'))
        end
        cd(oldpwd);
    end