% This is a top-level script that runs a series of MVPA and (optionally)
% shows the resulting graphs. It also saves the MVPA of each result and
% only runs those MVPA analyses that have not been run yet. 
% script takes reval vs noreval correlation measurement r for each
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
produce_graphs = 1;

%% Tweakable Parameters
aggregation_methods = aggregation_methods(5);
classifiers = classifiers(6);
LOCALIZER_OPTIONS = {'1', '2', '12', '21'};
TRSHIFT_OPTIONS = {'2','3'};
TRSELECT_OPTIONS = {'2','3'};
DATARANGE_OPTIONS = {'REST', 'MINIREST1', 'MINIREST2', 'MINIREST3', 'ALLPHASE2', 'PHASE2NOREST', };
DATA_PRUNING_OPTIONS = {'','REST_TRUNCATE_1', 'REST_TRIM_5', 'REST_TRIM_AND_TRUNCATE'};

setenv('SGE_LOCALIZER', LOCALIZER_OPTIONS{1}); % required, choices: 1, 2, 12, 21
setenv('SGE_ROI', 'FFA_PPA'); % required, choices: FFA_PPA
setenv('LOC2TRSHIFT', TRSHIFT_OPTIONS{2}) % optional, default:3, choices: 2, 3
setenv('LOC2TR', TRSELECT_OPTIONS{2}); % optional, default:'3', choices: 2, 3
setenv('SGE_DATARANGE', DATARANGE_OPTIONS{6}); % required, choices: REST, MINIREST1, MINIREST2, MINIREST3,  ALLPHASE2, PHASE2NOREST,
setenv('SGE_DATA_PRUNING', DATA_PRUNING_OPTIONS{1}); % optional, default: '', choices: 'REST_TRUNCATE_1', 'REST_TRIM_5', 'REST_TRIM_AND_TRUNCATE'
setenv('SGE_DATAPATH', '/usr/people/erhee/thesis/mvpa'); % optional
paramStr = sprintf('%s_%s_%s_%s_%s_%s', getenv('SGE_LOCALIZER'), getenv('SGE_ROI'), getenv('LOC2TRSHIFT'), getenv('LOC2TR'), getenv('SGE_DATARANGE'), getenv('SGE_DATA_PRUNING'));
disp(paramStr);
for classifier_index = 1:numel(classifiers)
    for aggregation_index = 1:numel(aggregation_methods)
        classifiers{classifier_index}
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
        %% {[No Noise] [No Reval]},     {[No Noise] [Reval]},     {[Noise] [No Reval]},     {[Noise Reval]}
        %% Reval VS No Reval 
        revalFMRIMean    = [ mean(validFMRIMeasure(:,   [1 3]) , 2) mean(validFMRIMeasure(:,   [2 4]) , 2) ];
        revalBehavioralMean  = [ mean(validBehavioralMeasure(:, [1 3]) , 2) mean(validBehavioralMeasure(:, [2 4]) , 2) ];
        [RHO_NoReval,PVAL_NoReval] = corr(revalFMRIMean(:,1), revalBehavioralMean(:, 1), 'type', 'Spearman' , 'tail', 'right');
        [RHO_Reval,PVAL_Reval] = corr(revalFMRIMean(:,2), revalBehavioralMean(:, 2), 'type', 'Spearman' , 'tail', 'left');
        reval_rhos(aggregation_index, classifier_index) = RHO_Reval;
        noreval_rhos(aggregation_index, classifier_index) = RHO_NoReval;
        reval_pvals(aggregation_index, classifier_index) = PVAL_Reval;
        noreval_pvals(aggregation_index, classifier_index) = PVAL_NoReval;

        %% Noise VS No Noise
        noiseFMRIMean    = [ mean(validFMRIMeasure(:,   [1 2]) , 2) mean(validFMRIMeasure(:,   [3 4]) , 2) ];
        noiseBehavioralMean  = [ mean(validBehavioralMeasure(:, [1 2]) , 2) mean(validBehavioralMeasure(:, [3 4]) , 2) ];
        [RHO_NoNoise,PVAL_NoNoise] = corr(noiseFMRIMean(:,1), noiseBehavioralMean(:, 1), 'type', 'Spearman' , 'tail', 'right');
        [RHO_Noise,PVAL_Noise] = corr(noiseFMRIMean(:,2), noiseBehavioralMean(:, 2), 'type', 'Spearman' , 'tail', 'left');
        noise_rhos(aggregation_index, classifier_index) = RHO_Noise;
        nonoise_rhos(aggregation_index, classifier_index) = RHO_NoNoise;
        noise_pvals(aggregation_index, classifier_index) = PVAL_Noise;
        nonoise_pvals(aggregation_index, classifier_index) = PVAL_NoNoise;

    end
end
for classifier_index = 1:numel(classifiers)
    classifier = classifiers{classifier_index};
    classifier_names{classifier_index} = regexprep(regexprep(classifier.train_funct_name,'train_',''),'_',' ');
end
unique_classes = unique(classifier_names);
%scatter_colors = linspace(1,10,numel(unique_classes));
%for classifier_uniquename_index = 1:numel(unique_classes)
%    for classifier_index = 1:numel(classifiers)
%        if strcmp(classifiers{classifier_index}.train_funct_name, unique_classes{classifier_uniquename_index}) == 1
%            classifier_colors(classifier_index) = scatter_colors(classifier_uniquename_index);
%        end
%    end
%end

%% Prepare Variables for Graph Title
param_localizer = getenv('SGE_LOCALIZER');
param_mask = getenv('SGE_ROI');
param_datarange = getenv('SGE_DATARANGE');
param_datapruning = getenv('SGE_DATA_PRUNING');

%% This is creating the Reval VS NoReval Graph
rhoFigure = figure('Color', [1 1 1], 'Position', [100, 100, 800, 800]);
hold on;
markers = {'o','*','+','d','s','^','p','h','.'}; % supports up to 8 aggregation methods for now; add more markers to support more.
markerSize = [10, 10, 10, 10, 10, 10, 10, 10, 10]; % supports up to 6 aggregation methods for now; add more to support more.
colors = ['b' 'g' 'r' 'c' 'm' 'y' 'k','w'];  % supports up to 8 aggregation methods
%gscatter(zeros(1,numel(unique_classes)+numel(aggregation_methods))-5, zeros(1,numel(unique_classes)+numel(aggregation_methods))-5, [unique_classes'; regexprep(aggregation_methods','_', ' ')], [colors(1:numel(unique_classes)) repmat('k',1,numel(aggregation_methods))], [repmat('.',1,numel(unique_classes)), cell2mat(markers(1:numel(aggregation_methods)))], [repmat(30,1,numel(unique_classes)), repmat(10, 1, numel(aggregation_methods))]); % to produce legends
gscatter([reval_rhos(aggregation_index,:) zeros(1,numel(aggregation_methods))] - 5 , [noreval_rhos(aggregation_index,:) zeros(1,numel(aggregation_methods))] - 5 , [classifier_names'; regexprep(aggregation_methods','_', ' ')], [colors(1:numel(unique_classes)) repmat('k',1,numel(aggregation_methods))], [repmat('.',1,numel(unique_classes)), cell2mat(markers(1:numel(aggregation_methods)))], [repmat(30,1,numel(unique_classes)), repmat(10, 1, numel(aggregation_methods))]);
for aggregation_index = 1:numel(aggregation_methods)
    gscatter(reval_rhos(aggregation_index,:) , noreval_rhos(aggregation_index,:), classifier_names', colors, markers{aggregation_index}, markerSize(aggregation_index), 'off', 'S2XS1 Reval R', 'S2XS1 No Reval R');
    aggregation_methods(aggregation_index);
    reval_rho_pval = [reval_rhos(aggregation_index,:);reval_pvals(aggregation_index,:)];
    noreval_rho_pval = [noreval_rhos(aggregation_index,:);noreval_pvals(aggregation_index,:)];
end
title(sprintf('Reval VS No Reval, Localizer:%s, Mask:%s, TestData:%s %s', param_localizer, regexprep(param_mask,'_',''), param_datarange, regexprep(param_datapruning,'_',' ')));
% draw axes
%axis([min(min(reval_rhos))-0.1 max(max(reval_rhos))+0.1 min(min(noreval_rhos))-0.1 max(max(noreval_rhos))+0.1]);
axis([-1 1 -1 1]);
plot([-1 1], [0, 0], '--k');
plot([0 0], [-1 1], '--k')
grid on
%saveFigure(sprintf('/usr/people/erhee/thesis/mvpa/figures/metaplots/%s_R.fig',paramStr));
%% This is creating the Noise VS No Noise Graph
rhoFigure = figure('Color', [1 1 1], 'Position', [100, 100, 800, 800]);
hold on;
markers = {'o','*','+','d','s','^','p','h','.'}; % supports up to 8 aggregation methods for now; add more markers to support more.
markerSize = repmat(10, 1, numel(aggregation_methods));
colors = ['b' 'g' 'r' 'c' 'm' 'y' 'k','w'];  % supports up to 8 aggregation methods
%gscatter(zeros(1,numel(unique_classes)+numel(aggregation_methods))-5, zeros(1,numel(unique_classes)+numel(aggregation_methods))-5, [unique_classes'; regexprep(aggregation_methods','_', ' ')], [colors(1:numel(unique_classes)) repmat('k',1,numel(aggregation_methods))], [repmat('.',1,numel(unique_classes)), cell2mat(markers(1:numel(aggregation_methods)))], [repmat(30,1,numel(unique_classes)), repmat(10, 1, numel(aggregation_methods))]); % to produce legends
gscatter([noise_rhos(aggregation_index,:) zeros(1,numel(aggregation_methods))] - 5 , [nonoise_rhos(aggregation_index,:) zeros(1,numel(aggregation_methods))] - 5 , [classifier_names'; regexprep(aggregation_methods','_', ' ')], [colors(1:numel(unique_classes)) repmat('k',1,numel(aggregation_methods))], [repmat('.',1,numel(unique_classes)), cell2mat(markers(1:numel(aggregation_methods)))], [repmat(30,1,numel(unique_classes)), repmat(10, 1, numel(aggregation_methods))]);
for aggregation_index = 1:numel(aggregation_methods)
    gscatter(noise_rhos(aggregation_index,:) , nonoise_rhos(aggregation_index,:), classifier_names', colors, markers{aggregation_index}, markerSize(aggregation_index), 'off', 'S2XS1 Noise R', 'S2XS1 No Noise R');
end
title(sprintf('Noise VS No Noise, Localizer:%s, Mask:%s, TestData:%s %s', param_localizer, regexprep(param_mask,'_',''), param_datarange, regexprep(param_datapruning,'_',' ')));
% draw axes
%axis([min(min(noise_rhos))-0.1 max(max(noise_rhos))+0.1 min(min(nonoise_rhos))-0.1 max(max(nonoise_rhos))+0.1]);
axis([-1 1 -1 1]);
plot([-1 1], [0, 0], '--k');
plot([0 0], [-1 1], '--k')
grid on;
%saveFigure(sprintf('/usr/people/erhee/thesis/mvpa/figures/metaplots/%s_N.fig',paramStr));
RlinearOutput = [];
PlinearOutput = [];
for classifier_index = 1:numel(classifiers)
    for aggregation_index = 1:numel(aggregation_methods)
        RlinearOutput(end+1:end+4) = [reval_rhos(aggregation_index, classifier_index),  noreval_rhos(aggregation_index, classifier_index),  noise_rhos(aggregation_index, classifier_index),  nonoise_rhos(aggregation_index, classifier_index)];
        PlinearOutput(end+1:end+4) = [reval_pvals(aggregation_index, classifier_index), noreval_pvals(aggregation_index, classifier_index), noise_pvals(aggregation_index, classifier_index), nonoise_pvals(aggregation_index, classifier_index)];
    end
end
%save(sprintf('/usr/people/erhee/thesis/mvpa/data_for_spreadsheet/%s_RValues.mat',paramStr), 'RlinearOutput');
%save(sprintf('/usr/people/erhee/thesis/mvpa/data_for_spreadsheet/%s_PValues.mat',paramStr), 'PlinearOutput');
%dlmwrite(sprintf('/usr/people/erhee/thesis/mvpa/data_for_spreadsheet/%s_RValues.txt',paramStr), RlinearOutput');
%dlmwrite(sprintf('/usr/people/erhee/thesis/mvpa/data_for_spreadsheet/%s_PValues.txt',paramStr), PlinearOutput');