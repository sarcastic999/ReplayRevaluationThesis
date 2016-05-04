%% a: no noise reval berlin
%% b: noise no reval london
%% c: noise reval paris             EXPECTED MAX REPLAY
%% d: no noise no reval kyoto       EXPECTED MIN REPLAY

%% rest onsets: NEWonset_MDP_regs_restonly; 
function [ results ] = mvpa_Loc1XLoc2_Face_Scene( subject, class_args )
    convolve_regressors = 1;
    baseDirFSL = '/jukebox/norman/reprev/';
    FSLsubDir   = [baseDirFSL 'subj/newS' num2str(subject)  '/'];
    maskExt         = {'.img';'.img';'.nii';'.mat'};
    maskfn          = {'face';'scene';'FS_mask';'FS_Searchmight'};
    %% MASK
    maskDir     = { [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ]};
    whichMasks      = 1:4;
    if isempty(getenv('SGE_DATAPATH'))
        datapath = '/usr/people/erhee/thesis/mvpa'; %default data path
    else
        datapath = getenv('SGE_DATAPATH');
    end
    
    outfold = sprintf('%s/MVPA_LOCALIZER_Face_Scene',datapath);
    if ~exist(outfold)
        mkdir(outfold);
    end;
    results =[];
    tic
    
    %% Paths Localizer Volumes
    % loc 2
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
    feat_dir = lsdir(1).name;
    raw_loc2_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);
    
    % loc 1
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc/*.feat',subject));
    feat_dir    = lsdir(1).name;
    raw_loc1_filename   = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc/%s/filtered_func_data.nii',subject,feat_dir);

    
    %% load localizer 1 regs
    regs_folder     = [baseDirFSL 'behavioral/newS' num2str(subject) '/onsets/']; %[onsdir 'newregs/'];
    reg_loc1_file   = 'NEWregLoc_RepReval_3CAT_SPM_shift3_dur3_1run';
    regsFile_train  = [regs_folder reg_loc1_file '.mat'];
    if ~exist(regsFile_train)
        printf('ERROR: SUBJECTS DOES NOT HAVE REGRESSORS FOR LOCALIZER 1');
        return;
    end
    
    load(regsFile_train);
    localizer1_regs = regs;
    %% pad volumes
    TrainVol    = spm_read_hdr(raw_loc1_filename);
    epiLenTrain = TrainVol.dime.dim(5); 
    clear TrainVOl;
    if (convolve_regressors)
        % undo shift by 3
        localizer1_regs.conds = localizer1_regs.conds(:,4:end);
        localizer1_regs.runs = localizer1_regs.runs(:,4:end);
        
    end
    if epiLenTrain<length(regs.conds) % shorten regs
        localizer1_regs.conds = localizer1_regs.conds(:,1:epiLenTrain);
        localizer1_regs.runs  = localizer1_regs.runs(1: epiLenTrain);
    else
        % pad
        localizer1_regs.conds(:, end+1:epiLenTrain) = 0;
        localizer1_regs.runs(end+1:epiLenTrain)     = max(regs.runs);
    end
        
    %% load localizer 2 regs - first 5 subjects do not have localizer 2
    if subject < 5
        printf('ERROR: SUBJECTS 1~5 DO NOT HAVE LOCALIZER 2');
        return;
    end
    s = subject;
    if (convolve_regressors)
        loc2_shiftTRs = 0;
        localizer2_regs = loc2_createRegressor(subject, loc2_shiftTRs);
    else
        loc2_shiftTRs = 2;
        localizer2_regs = loc2_createRegressor(subject, loc2_shiftTRs);
    end
    % Delete Last TR? -- see mvpa_Loc1XLoc2_3set_predction_accuracies.m for motivation into why 3rd TR is not good.
    if(~isempty(getenv('LOC2TR')))
        loc2_numTRs = str2num(getenv('LOC2TR')); % use first x TRs only
    else
        loc2_numTRs = 3;
    end
    
    %% combine all NIFTI images
    raw_filenames = {raw_loc1_filename ; raw_loc2_filename};
    %% combine the regressors
    clear regs;
    regsloc1FS.conds = localizer1_regs.conds(1:2, :);
    regsloc1FS.runs = localizer1_regs.runs;
    regsloc2FS.conds = localizer2_regs.conds(1:2, :);
    regsloc2FS.runs = localizer2_regs.runs;
    regs.conds = [regsloc1FS.conds regsloc2FS.conds];
    
    %% LOCALIZER1 IS RUN 1 and LOCALIZER2 are RUN 2
    regs.runs  = [regsloc1FS.runs regsloc2FS.runs*2];
   
    %% Initialize subject
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ; 
    %% Load all masks, and load the pattern from nifti, masked by each mask individually
    for maskIdx = whichMasks
        if (strcmp(maskExt{maskIdx},'.mat') == 1)
            maskFile  = sprintf('/usr/people/erhee/thesis/mvpa/Searchmight/InformationMaps/FSmask_gnb_subject%d.mat',subject);
            load(maskFile);
            subj = init_object(subj, 'mask', 'FS_Searchmight');
            subj = set_mat(subj, 'mask', 'FS_Searchmight', FSmask);
            subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_filenames);
        else   
            maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
            subj = load_spm_mask(subj,    maskfn{maskIdx}, maskFile);
            subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_filenames);
        end
    end

    %% 7) initialize regressors
    subj = initset_object(subj,'regressors','conds', regs.conds);
    

    %% 8) define selectors or 'runs'
    subj = initset_object(subj, 'selector', 'runs', regs.runs);
    
    rmpath '/usr/people/erhee/searchmight/SearchmightToolbox.Linux_x86_64.0.2.5' %xrepmat problem;
    %% Convolve Regressors if necessary
    if(convolve_regressors)
        subj = convolve_regressors_afni(subj, 'conds', 'runs','overwrite_if_exist', true, 'scale_to_one', true, 'binarize_thresh', 0.5, 'do_plot', true);
        convolved_regressor_name = 'conds_conv';
        condnames = {'faces', 'scenes'};
        subj = set_objfield(subj, 'regressors', convolved_regressor_name, 'condnames', condnames);
        subj = create_norest_sel(subj, convolved_regressor_name);
        subj = create_xvalid_indices(subj, 'runs', ...
            'actives_selname',  [convolved_regressor_name '_norest'], ...
            'ignore_jumbled_runs', true, ...
            'new_selstem','runs_norest_xval');
        for maskIdx = whichMasks % 1:length(maskfn);
            subj = zscore_runs(subj,  ['epi'  num2str(maskIdx)], 'runs', ...
                'actives_selname',  [convolved_regressor_name '_norest'], ...
                'ignore_jumbled_runs', true);
            runSelector = 'runs_norest_xval';
            summarize(subj, 'display_groups', false)
            epiname = ['epi'  num2str(maskIdx)  '_z'];
            [subj results{ maskIdx}] = ...   cross_validation(subj, ['epi'  num2str(maskIdx) '_z']  , 'conds', 'runs_xval', ...
                cross_validation(subj, ... % [SUBJ RESULTS] = CROSS_VALIDATION(SUBJ,PATIN,REGSNAME,SELNAME,MASKGROUP,CLASS_ARGS...)
                epiname , ...  zscored epi patterns that go in
                convolved_regressor_name, ... this is the regs files
                runSelector, ... these are the selectors. 1 train, 2 test, 0 ignore
                maskfn{maskIdx}, ... 'epi1_z_thresh0.05' , ... group of masks that will be applied
                class_args);
        end
         %% SAVE RESULTS
         processed_params = processed_param_string(class_args);
         outfile = sprintf('%s/Loc1XLoc2Convolved_%dTRs_subject%d_%s_%s_%s.mat', outfold, loc2_numTRs, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
         save(outfile, 'results', 'maskfn', 'subject', 'class_args');

    else
        condnames = {'faces', 'scenes'};
        subj = set_objfield(subj, 'regressors', 'conds', 'condnames', condnames);
        subj = create_norest_sel(subj,  'conds');
        subj = create_xvalid_indices(subj, 'runs', ...
            'actives_selname',  'conds_norest', ...
            'ignore_jumbled_runs', true, ...
            'new_selstem','runs_norest_xval');
        for maskIdx = whichMasks % 1:length(maskfn);
            subj = zscore_runs(subj,  ['epi'  num2str(maskIdx)], 'runs', ...
                'actives_selname',  'conds_norest', ...
                'ignore_jumbled_runs', true);
            runSelector = 'runs_norest_xval';
            summarize(subj, 'display_groups', false)
            epiname = ['epi'  num2str(maskIdx)  '_z'];
            [subj results{ maskIdx}] = ...   cross_validation(subj, ['epi'  num2str(maskIdx) '_z']  , 'conds', 'runs_xval', ...
                cross_validation(subj, ... % [SUBJ RESULTS] = CROSS_VALIDATION(SUBJ,PATIN,REGSNAME,SELNAME,MASKGROUP,CLASS_ARGS...)
                epiname , ...  zscored epi patterns that go in
                'conds', ... this is the regs files
                runSelector, ... these are the selectors. 1 train, 2 test, 0 ignore
                maskfn{maskIdx}, ... 'epi1_z_thresh0.05' , ... group of masks that will be applied
                class_args);
        end
         %% SAVE RESULTS
         processed_params = processed_param_string(class_args);
         outfile = sprintf('%s/Loc1XLoc2Shift%d_%dTRs_subject%d_%s_%s_%s.mat', outfold, loc2_shiftTRs, loc2_numTRs, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
         save(outfile, 'results', 'maskfn', 'subject', 'class_args');
    end

end