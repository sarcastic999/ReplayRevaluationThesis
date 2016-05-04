function plot_scatters_collapse( invecall, probrevall, xlab_text)
%plot_scatters_collapse_noise
%xlab_text=('Mean S1 CAT X S2 MOTOR Replay')
figure1 = figure('Color',[1 1 1], 'Position',[100, 100, 800, 400]);

% Create subplot
subplot1 = subplot(1,2,1,'Parent',figure1,'FontSize',15); 
%subplot(1,2,1)

invec    = [ mean(invecall(:,   [1 3]) , 2) mean(invecall(:,   [2 4]) , 2) ];
probrev  = [ mean(probrevall(:, [1 3]) , 2) mean(probrevall(:, [2 4]) , 2) ];


scatter(invec(:, 1), probrev(:,1),...
    'MarkerFaceColor', [1 0 0 ], ...[0 .2 1  ], ...[0.0431372560560703 0.517647087574005 0.780392169952393],...
    'MarkerEdgeColor', [1 0 0 ], ...[0 .2 1  ], ...[0.0431372560560703 0.517647087574005 0.780392169952393],...
    'LineWidth',4); 
lsline
[RHO,PVAL] = corr(probrev(:,1), invec(:, 1),...
                    'type', 'Spearman' , 'tail', 'right');
title(['No Reval: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('Mean No Reval Behavioral Score')
subplot2 = subplot(1,2,2,'Parent',figure1,'FontSize',15); 

%subplot(1,2,2)
scatter(invec(:, 2), probrev(:,2),...
    'MarkerFaceColor', [1 0 0 ], ...[ 0 .2 1  ], ...[0.0431372560560703 0.517647087574005 0.780392169952393],...
    'MarkerEdgeColor', [1 0 0 ], ...[ 0 .2 1  ], ...[0.0431372560560703 0.517647087574005 0.780392169952393],...
    'LineWidth',4); 
lsline
[RHO,PVAL] = corr(probrev(:,2), invec(:, 2), ...
                    'type', 'Spearman' , 'tail', 'left');
title(['Reval: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('Mean Reval Behavioral Score')
%% Load Preset Classifiers
load_classifiers;
for classifier_index = 1:numel(classifiers)
    classifier = classifiers{classifier_index};
    classifier_names{classifier_index} = regexprep(regexprep(classifier.train_funct_name,'train_',''),'_',' ');
end
%% Prepare Variables for Graph Title
param_localizer = getenv('SGE_LOCALIZER');
param_mask = getenv('SGE_ROI');
param_datarange = getenv('SGE_DATARANGE');
param_datapruning = regexprep(regexprep(getenv('SGE_DATA_PRUNING'),'_',' '),'REST ','');
param_classifier = getenv('SGE_CLASSIFIER_ID');

suptitle(sprintf('Localizer:%s, Mask:%s, TestData:%s %s, Classifier:%s', param_localizer, regexprep(param_mask,'_',''), param_datarange, param_datapruning, classifier_names{str2num(param_classifier)}));

end