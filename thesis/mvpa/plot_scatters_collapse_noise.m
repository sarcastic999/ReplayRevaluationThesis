function plot_scatters_collapse_noise( invecall, probrevall, xlab_text)

%xlab_text=('Mean S1 CAT X S2 MOTOR Replay')
figure1 = figure('Color',[1 1 1], 'Position',[100, 100, 800, 400]);

% Create subplot
subplot1 = subplot(1,2,1,'Parent',figure1,'FontSize',15); 

invec    = [ mean(invecall(:,   [1 2]) , 2) mean(invecall(:,   [3 4]) , 2) ];
probrev  = [ mean(probrevall(:, [1 2]) , 2) mean(probrevall(:, [3 4]) , 2) ];


scatter(invec(:, 1), probrev(:,1)), lsline
[RHO,PVAL] = corr(probrev(:,1), invec(:, 1),...
                    'type', 'Spearman' , 'tail', 'right');
title(['No Noise: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('Mean No Noise Behavioral Score')
subplot1 = subplot(1,2,2,'Parent',figure1,'FontSize',15); 
scatter(invec(:, 2), probrev(:,2)), lsline
[RHO,PVAL] = corr(probrev(:,2), invec(:, 2), ...
                    'type', 'Spearman' , 'tail', 'left');
title(['Noise: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('Mean Noise Behavioral Score')
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