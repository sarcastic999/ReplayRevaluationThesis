% does cross validation decoding on the localizer
%% a: no noise reval berlin
%% b: noise no reval london
%% c: noise reval paris             EXPECTED MAX REPLAY
%% d: no noise no reval kyoto       EXPECTED MIN REPLAY

%% rest onsets: NEWonset_MDP_regs_restonly; 
function [ results ] = mvpa_Loc2XRest_Face_Scene_cross_validator( subject, class_args )
    baseDirFSL = '/jukebox/norman/reprev/';
    
    maskExt         = {'.img';'.img';'.nii'};
    maskfn          = {'face';'scene';'FS_mask'};

    whichMasks      = 1:numel(maskfn);
    if isempty(getenv('SGE_DATAPATH'))
        datapath = '/usr/people/erhee/thesis/mvpa'; %default data path
    else
        datapath = getenv('SGE_DATAPATH');
    end
        
    if(~isempty(getenv('LOC2TRSHIFT')))
        loc2_shiftTRs = str2num(getenv('LOC2TRSHIFT'));
    else
        loc2_shiftTRs = 3;
    end
    % Delete Last TR? -- see mvpa_Loc1XLoc2_3set_predction_accuracies.m for motivation into why 3rd TR is not good.
    if(~isempty(getenv('LOC2TR')))
        loc2_numTRs = str2num(getenv('LOC2TR')); % use first x TRs only
    else
        loc2_numTRs = 3;
    end
    
    outfold = sprintf('%s/MVPA_Rest_Face_Scene',datapath);
    if ~exist(outfold)
        mkdir(outfold);
    end;
    results =[];
    tic
    s = subject;
    regs = loc2_createRegressor_cross_validator(subject);
    runtime     = datestr(now);
    %% MASK
    maskDir     = { [ baseDirFSL 'results_spm/newS' num2str(s)  '/loc2_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(s)  '/loc2_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(s)  '/loc2_glm/' ]};


    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% MDP:: COMBINE ALL RELEVANT RUNS AND ADD THEM TO THE END OF THE FILE
    MDPfolder     = [ baseDirFSL 'behavioral/newS' num2str(s) '/onsets/restOnsets/']; %'/MDPonsets/'];
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
    feat_dir = lsdir(1).name;
    raw_volume_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);
    %% 4a) Initialize subject
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ; 
    %% 4b) Load all masks, and load the pattern from nifti, masked by each mask individually
    for maskIdx = whichMasks
        maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
        subj = load_spm_mask(subj,    maskfn{maskIdx}, maskFile);
        subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_volume_filename);
    end


    %% 7) initialize regressors
    subj = initset_object(subj,'regressors','conds', regs.conds);

    %% 8) define selectors or 'runs'
    subj = initset_object(subj, 'selector', 'runs', regs.runs);

    %% 9) define condnames
    % XXX CHANGED THIS 2 REFLECT 2 CATEGORIES. CHANGE FOR OBJECT
    condnames = {'faces', 'scenes'} %, 'objects'};
    subj = set_objfield(subj, 'regressors', 'conds', 'condnames', condnames);

    %% 10) EXCLUDE the rest...

    subj = create_norest_sel(subj,  'conds');


    %% 11) Create cross-validation indices

    subj = create_xvalid_indices(subj, 'runs', ...
        'actives_selname',  'conds_norest', ...
        'ignore_jumbled_runs', true, ...
        'ignore_runs_zeros', true, ...
        'new_selstem','runs_norest_xval');

    %% 13) run mvpa for each mask
    for maskIdx = whichMasks % 1:length(maskfn);
        % IM NOTE: jordan is particularly concerned whether zscoring is a
        % good idea
        %% NB: no zscoring
        %% 13.a) Z score
        subj = zscore_runs(subj,  ['epi'  num2str(maskIdx)], 'runs', ...
            'actives_selname',  'conds_norest', ...
            'ignore_jumbled_runs', true);
        runSelector = 'runs_norest_xval';

        %% 13.a.2) Feature select with anova: this generates masks!
        %statmap_arg.use_mvpa_ver = true;
        %subj = feature_select(subj, ['epi'  num2str(maskIdx) '_z'], 'conds', 'runs_norest_xval');
        summarize(subj, 'display_groups', false)
        %% 13.b) store results for each mask
        %feature_sel=1;
        %if feature_sel
        %   epiname = ['epi' num2str(maskIdx) '_z_anova'];
        %else
        epiname = ['epi'  num2str(maskIdx)  '_z'];
        %end
        %if (strcmp(class_args.train_funct_name,'train_svm')==0)
        %    [svm1 svm2 svm12] = SVMPredictor(subject, class_args);
        %else
            [subj results{ maskIdx}] = ...   cross_validation(subj, ['epi'  num2str(maskIdx) '_z']  , 'conds', 'runs_xval', ...
                cross_validation(subj, ... % [SUBJ RESULTS] = CROSS_VALIDATION(SUBJ,PATIN,REGSNAME,SELNAME,MASKGROUP,CLASS_ARGS...)
                epiname , ...  zscored epi patterns that go in
                'conds', ... this is the regs files
                runSelector, ... these are the selectors. 1 train, 2 test, 0 ignore
                maskfn{maskIdx}, ... 'epi1_z_thresh0.05' , ... group of masks that will be applied
                class_args);
        %end
        % results{s, maskIdx, run}.imagery_TRs = find(imregs.conds==1);
        % totres(maskIdx, s, run) = results{s,maskIdx, run}.total_perf;
    end

     %% SAVE RESULTS
     jsonrep = savejson('',class_args);
     comma_indices = find(jsonrep == ',');
     custom_param_begin_index = comma_indices(2)+1;
     unprocessed_params = jsonrep(custom_param_begin_index:end);
     processed_params = regexprep(regexprep(unprocessed_params,'\n|\t|}|\"',''),': ','_');
     outfile = sprintf('%s/cv_Loc2Shift%d_%dTRsXRest_subject%d_%s_%s_%s.mat', outfold, loc2_shiftTRs, loc2_numTRs, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
     save(outfile, 'results', 'maskfn', 'subject', 'class_args');

end