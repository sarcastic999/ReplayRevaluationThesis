function plot_scatters_all( invecall, probrev, xlab_text)


% xlab_text = 'S1 X S2 X  M2-M1';

figure1 = figure('Color',[1 1 1], 'Position',[100, 100, 800, 800]);

% Create subplot
subplot1 = subplot(2,2,1,'Parent',figure1,'FontSize',15); 
%subplot(2,2,1)
scatter(    invecall(:, 1), probrev(:,1)), lsline
[RHO,PVAL] = corr(probrev(:,1), invecall(:, 1),'type', 'Spearman' , 'tail', 'both');
title(['No Reval No noise: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('P3-P1');

subplot2 = subplot(2,2,2,'Parent',figure1,'FontSize',15); 

%subplot(2,2,2)
scatter(    invecall(:, 2), probrev(:,2)), lsline
[RHO,PVAL] = corr(probrev(:,2), invecall(:, 2), ...
                    'type', 'Spearman' , 'tail', 'both');
title(['Reval No Noise: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('P3-P1');
subplot3 = subplot(2,2,3,'Parent',figure1,'FontSize',15); 
% subplot(2,2,3)
scatter(    invecall(:, 3), probrev(:,3)), lsline
[RHO,PVAL] = corr(probrev(:,3), invecall(:, 3), ...
                    'type', 'Spearman' , 'tail', 'both');
title(['No Reval Noise: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('P3-P1');
subplot4 = subplot(2,2,4,'Parent',figure1,'FontSize',15); 

%subplot(2,2,4)
scatter(    invecall(:, 4), probrev(:,4)), lsline
[RHO,PVAL] = corr(probrev(:,4), invecall(:, 4), ...
                    'type', 'Spearman' , 'tail', 'both');
title(['Reval Noise: r:' num2str(RHO) ' p:' num2str(PVAL)] )
xlabel( xlab_text)
ylabel('P3-P1');
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