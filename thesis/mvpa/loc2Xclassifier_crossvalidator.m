function [ classifier_performance ] = loc2Xclassifier_crossvalidator()
    %% Load Classifiers
    load_classifiers;
    classifiers = classifiers(1:30); % use only classifiers used in parameter exploration
    VALID_SUBJECTS = [1:9 11:23 25:26];
    classifier_performance = [];
    taskId = getenv('SGE_TASK_ID');
    setenv('LOC2TRSHIFT', '2') % optional, default:3, choices: 2, 3
    setenv('LOC2TR', '2'); % optional, default:'3', choices: 2, 3
    subject = 19%str2num(taskId);
    if (subject < 5 || subject == 10 || subject == 24)
        return;
    end
    environment_setup;
    %% Load Subject Localizer Pattern
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
    feat_dir = lsdir(1).name;
    raw_volume_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);

    if exist(raw_volume_filename)==0
        zippedfile = sprintf('%s.gz', raw_volume_filename);
        gunzip(zippedfile);
    end
    localizerVolume    = spm_read_hdr(raw_volume_filename);
    localizerLength = localizerVolume.dime.dim(5); %% Total Length of localizer

    %% Load Subject Localizer Regressors
    regsloc = loc2_createRegressor(subject);
    if localizerLength<length(regsloc.conds) % shorten regs
        regsloc.conds = regsloc.conds(:,1:localizerLength);
        regsloc.runs  = regsloc.runs(1: localizerLength);
    else
        % padd
        regsloc.conds(:, end+1:localizerLength) = 0;
        regsloc.runs(end+1:localizerLength)     = max(regsloc.runs);
    end
    regsloc.conds = regsloc.conds(1:2, :); % getting rid of object, i.e. 3rd row
    %% Initialize Subject
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ;

    %% Load Subject Masks
    maskExt         = {'.img';'.img'};
    maskfn          = {'face';'scene'};
    for maskIdx = 1:numel(maskfn)
        maskFile  = sprintf('%s%s%s',sprintf('/jukebox/norman/reprev/results_spm/newS%d/localizer_glm/',subject), maskfn{maskIdx}, maskExt{maskIdx});
        subj = load_spm_mask(subj,    maskfn{maskIdx}, maskFile);
        subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_volume_filename);
    end

    %% Separate Face and Scene runs
    faceRunBegins = find((regsloc.conds(1,:) - [0 regsloc.conds(1,1:end-1)]) == 1);
    faceRunEnds = find((regsloc.conds(1,:) - [regsloc.conds(1,2:end), 0]) == 1);
    sceneRunBegins = find((regsloc.conds(2,:) - [0 regsloc.conds(2,1:end-1)]) == 1);
    sceneRunEnds = find((regsloc.conds(2,:) - [regsloc.conds(2,2:end), 0]) == 1);
    for i = 1:numel(faceRunBegins)
        regsloc.runs(faceRunBegins(i):faceRunEnds(i)) = i;
        regsloc.runs(sceneRunBegins(i):sceneRunEnds(i)) = i;
    end

    %% Initialize Subject Regressors
    subj = initset_object(subj,'regressors','conds',regsloc.conds);
    subj = initset_object(subj, 'selector', 'runs',regsloc.runs);
    condnames = {'faces', 'scenes'};
    subj = set_objfield(subj, 'regressors', 'conds', 'condnames', condnames);
    subj = create_norest_sel(subj,  'conds');

    %% LOOCV
    subj = create_xvalid_indices(subj, 'runs', ...
        'actives_selname',  'conds_norest', ...
        'ignore_jumbled_runs', true, ...
        'new_selstem','runs_norest_xval');


    %% Test each classifier accuracy
    for maskIdx = 1:numel(maskfn)
        subj = zscore_runs(subj,  ['epi'  num2str(maskIdx)], 'runs','actives_selname',  'conds_norest', 'ignore_jumbled_runs', true);
        runSelector = 'runs_norest_xval';
        summarize(subj, 'display_groups', false)
        epiname = ['epi'  num2str(maskIdx)  '_z'];
        % for each classifier
        for classifier_index = 1:numel(classifiers)
            class_args = classifiers{classifier_index};
            [subj results] = ...   
                cross_validation(subj, ... % [SUBJ RESULTS] = CROSS_VALIDATION(SUBJ,PATIN,REGSNAME,SELNAME,MASKGROUP,CLASS_ARGS...)
                epiname , ... 
                'conds', ...
                runSelector, ...
                maskfn{maskIdx}, ...
                class_args);
            accuracy = results.total_perf;
            classifier_performance(classifier_index, maskIdx) = accuracy;
            classifier_results{classifier_index, maskIdx} = results;
        end            
    end
% classifier_performance = classifier_performance / numel(VALID_SUBJECTS); % mean;
disp(classifier_performance);
save(sprintf('MVPA_xval/loc2/subject%d_classifier_xval.mat', subject),'classifier_performance', 'classifier_results');
end