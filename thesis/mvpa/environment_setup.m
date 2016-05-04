%% Configuration Parameters, to be run before scripts
if not(exist('env_setup'))
    fprintf('Setting Up Environment...\n');
    setup_mvpa_toolbox();
    addpath '/usr/people/erhee/netlab'
%    addpath '/usr/people/erhee/searchmight/SearchmightToolbox.Linux_x86_64.0.2.5'
%    addpath '/usr/people/erhee/adaboost'
    addpath '/usr/people/erhee/libsvm/libsvm-3.20/matlab'
    addpath '/usr/people/erhee/jsonlab/jsonlab'
    if strcmp(getenv('OS'),'Linux') == 1 % rondo
        juke = '/jukebox/';
        baseDirFSL = strcat(juke, 'norman/reprev/');
        output_directory_root = '/usr/people/erhee/thesis/mvpa/';
        produce_graphs = 1;
        env_setup = 1;
    elseif strcmp(getenv('OS'),'Windows_NT') == 1 % asus
        baseDirFSL = 'G:/norman/reprev/';
        output_directory_root = 'G:/thesis/mvpa/';
        produce_graphs = 1;
        env_setup = 1;
    end
    fprintf('Finished Setting Up Environment...\n');
end