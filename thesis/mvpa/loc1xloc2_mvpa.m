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
if isempty(getenv('SGE_DATAPATH'))
    datapath = '/usr/people/erhee/thesis/mvpa'; %default data path
else
    datapath = getenv('SGE_DATAPATH');
end

setenv('LOC2TR','3');
    

%% Tweakable Parameters
%classifiers = classifiers([1:28]);
VALID_SUBJECTS = [5:9 11:23 25:26];
groupFaceMaskPerf = [];
groupSceneMaskPerf = [];
for classifier_index = 1:numel(classifiers)
    class_args = classifiers{classifier_index};
    faceMaskPerf = [];
    sceneMaskPerf = [];
    for subj = VALID_SUBJECTS
        processed_params = processed_param_string(class_args);
        loc2_shiftTRs = 2;
        % Delete Last TR? -- see mvpa_Loc1XLoc2_3set_predction_accuracies.m for motivation into why 3rd TR is not good.
        if(~isempty(getenv('LOC2TR')))
            loc2_numTRs = str2num(getenv('LOC2TR')); % use first x TRs only
        else
            loc2_numTRs = 3;
        end
        filePath = sprintf('%s/MVPA_LOCALIZER_Face_Scene/Loc1XLoc2Shift%d_%dTRs_subject%d_%s_%s_%s.mat', datapath, loc2_shiftTRs, loc2_numTRs, subj, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
        % if file doesn't exist, MVPA analysis hasn't been run yet.
        if ~(exist(filePath, 'file') == 2)
            mvpa_Loc1XLoc2_Face_Scene(subj,class_args)
        end
        clear results;
        display(filePath);
        load(filePath);
        faceMaskPerf(end+1) = results{1}.iterations(2).perf;
        sceneMaskPerf(end+1) = results{2}.iterations(2).perf;
    end
    groupFaceMaskPerf(end+1) = mean(faceMaskPerf);
    groupSceneMaskPerf(end+1) = mean(sceneMaskPerf);
end
figure;
hold on;
for classifier_index = 1:numel(classifiers)
    classifier = classifiers{classifier_index};
    classifier_names{classifier_index} = regexprep(regexprep(classifier.train_funct_name,'train_',''),'_',' ');
    bar(classifier_index,mean([groupFaceMaskPerf(classifier_index) groupSceneMaskPerf(classifier_index)]));
end
set(gca, 'XTick', 1:numel(classifiers), 'XTickLabel', classifier_names);
unique_classes = unique(classifier_names);

%% Plot Performance Face X Scene
rhoFigure = figure('Color', [1 1 1], 'Position', [100, 100, 800, 800]);
hold on;
markers = ['o','*','+','d','s','^']; % supports up to 6 aggregation methods for now; add more markers to support more.
markerSize = [10, 10, 10, 10, 10, 10]; % supports up to 6 aggregation methods for now; add more to support more.
colors = ['b' 'g' 'r' 'c' 'm' 'y']; 
gscatter(groupFaceMaskPerf , groupSceneMaskPerf, classifier_names', colors, markers, markerSize, 'on', 'Face Mask Performance', 'Scene Mask Performance');
title('Train:Loc1 Test:Loc2 Performances for Masks: Face & Scene');
% draw axes
%axis([min(min(reval_rhos))-0.1 max(max(reval_rhos))+0.1 min(min(noreval_rhos))-0.1 max(max(noreval_rhos))+0.1]);
%axis([0 1 0 1]);