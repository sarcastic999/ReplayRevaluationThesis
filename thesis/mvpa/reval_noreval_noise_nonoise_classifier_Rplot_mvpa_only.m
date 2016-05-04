% This script takes reval vs noreval correlation measurement r for each
% classifier, parameter condition and maps it onto a 2-dimensional
% reval r vs noreval r with each color denoting the classifier type.

%% This is a top-level script
clear all
%% Load Preset Classifiers
load_classifiers;

%% Experiment Parameters
load_aggregation_methods;

%% environment setup
environment_setup;
produce_graphs = 0;
tid = str2num(getenv('SGE_TASK_ID'));

tid = tid -1; % 0 ~ 36
id1 = floor(tid/12) + 1; % 1, 2, or 3
tid = tid - (id1-1)*12; % 1~24
id2 = floor(tid/6) + 1; % 1,2
tid = tid - (id2-1)*6; % 1~12
id3= floor(tid/3) + 1; %1,2
tid = tid - (id3-1) * 3; % 1~6
id4 = tid+1; % 1,2,3


%when id1=1, then id2=2 and id3=2
% if loc1, then TR SHIFT = 3 and TR SELECT = 3
if id1==1 && (id2~=2 || id3~=2)
    return;  
end
disp([id1 id2 id3 id4]);
%% only run mvpa,
setenv('SGE_MVPA_ONLY', '1'); % optional; default = 0, choices = 1, 0


%% Tweakable Parameters
aggregation_methods = aggregation_methods(1:8);
classifiers = classifiers(1:30);
LOCALIZER_OPTIONS = {'1', '2', '12'};%, '21'};
TRSHIFT_OPTIONS = {'2','3'};
TRSELECT_OPTIONS = {'2','3'};
DATARANGE_OPTIONS = {'REST', 'ALLPHASE2', 'PHASE2NOREST', };

setenv('SGE_LOCALIZER', LOCALIZER_OPTIONS{id1}); % required, choices: 1, 2, 12, 21
setenv('SGE_ROI', 'FFA_PPA'); % required, choices: FFA_PPA
setenv('LOC2TRSHIFT', TRSHIFT_OPTIONS{id2}) % optional, default:3, choices: 2, 3
setenv('LOC2TR', TRSELECT_OPTIONS{id3}); % optional, default:'3', choices: 2, 3
setenv('SGE_DATARANGE', DATARANGE_OPTIONS{id4}); % required, choices: REST, MINIREST1, MINIREST2, MINIREST3,  ALLPHASE2, PHASE2NOREST,
setenv('SGE_DATAPATH', '/usr/people/erhee/thesis/mvpa'); % optional
paramStr = sprintf('%s_%s_%s_%s_%s_%s', getenv('SGE_LOCALIZER'), getenv('SGE_ROI'), getenv('LOC2TRSHIFT'), getenv('LOC2TR'), getenv('SGE_DATARANGE'), getenv('SGE_DATA_PRUNING'));
for classifier_index = 1:numel(classifiers)
    for aggregation_index = 1:numel(aggregation_methods)
        aggregation_method = aggregation_methods{aggregation_index};
        class_args = classifiers{classifier_index};
        setenv('SGE_AGG', aggregation_method);
        setenv('SGE_CLASSIFIER_ID', num2str(classifier_index));
        if isempty(getenv('SGE_LOCALIZER'))
            setenv('SGE_LOCALIZER', num2str(1)); % change for localizer. 1 = loc1, 2 = loc2, 12 = loc1&2(jointly trained) 21 = loc1&2(independently trained)
        end
        if isempty(getenv('SGE_ROI'))
            setenv('SGE_ROI', 'FFA_PPA'); % change for mask
        end
        if isempty(getenv('SGE_DATARANGE'))
            setenv('SGE_DATARANGE', 'REST');
        end
        clear validFMRIMeasure;
        replanning_behavioralVSfMRI_FFAPPA;
    end
end
