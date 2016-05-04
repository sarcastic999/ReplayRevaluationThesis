% incomplete
%% a: no noise reval berlin
%% b: noise no reval london
%% c: noise reval paris             EXPECTED MAX REPLAY
%% d: no noise no reval kyoto       EXPECTED MIN REPLAY

%% rest onsets: NEWonset_MDP_regs_restonly; 
function [ results ] = mvpa_Loc2XALLPHASE2_Face_Scene( subject, class_args )
    baseDirFSL = '/jukebox/norman/reprev/';
    FSLsubDir   = [baseDirFSL 'subj/newS' num2str(subject)  '/'];
    maskExt         = {'.img';'.img';'.nii'};
    maskfn          = {'face';'scene';'FS_mask'};

    whichMasks      = 1:2;
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
    
    outfold = sprintf('%s/MVPA_ALLPHASE2_Face_Scene',datapath);
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
    
    %% load localizer 2 regs - first 5 subjects do not have localizer 2
    if subject < 5
        printf('ERROR: SUBJECTS 1~4 DO NOT HAVE LOCALIZER 2');
        return;
    end
    s = subject;
    localizer2_regs = loc2_createRegressor(subject);
    
    %% MASK
    maskDir     = { [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ]};
    %% Load Rest Period Volumes
    for run = 1:4
        %% 2.b) MDP NIFTIs repRev runs
        atest    = dir([ FSLsubDir 'NII/prestat_run' num2str(run) '/']);
        feat_dir = atest(1).name; %'/+.feat/' or one with the most ++, aka the newest
        run_ima_nifti_dir   = [FSLsubDir 'NII/prestat_run' num2str(run) '/' feat_dir '/']; %[subDir '/data/run' num2str(run) '/'];
        raw_ima_filenames{run}   =  [run_ima_nifti_dir 'filtered_func_data.nii']; %cellstr(spm_select('FPList', run_ima_nifti_dir, filter));

        % c) clear regs to avoid misakes/overwrites
        clear regs;
        %% b) test set
        regs = mvpa_phase2_selector_generator(subject, run);

        TestVol     = spm_read_hdr(raw_ima_filenames{run});
        epiLentest  = TestVol.dime.dim(5);

        clear TestVol;
        if epiLentest<length(regs.conds) % shorten regs
            imregs{run}.conds = regs.conds(:,1:epiLentest);
            imregs{run}.runs  = regs.runs(1: epiLentest);
        else
            % padd
            imregs{run} = regs;
            imregs{run}.conds(:, end+1:epiLentest) = 0;
            imregs{run}.runs(end+1:epiLentest)     = max(imregs{run}.runs);
        end

    end
    %% 3.c.) combine all NIFTI images
    raw_filenames = {raw_loc2_filename ;    raw_ima_filenames{1} ;...
        raw_ima_filenames{2};...
        raw_ima_filenames{3};...
        raw_ima_filenames{4}};
    %% 6c) combine the regressors
    clear regs;
    regslocFS.conds = localizer2_regs.conds(1:2, :);
    regslocFS.runs = localizer2_regs.runs;
    regs.conds = [regslocFS.conds imregs{1}.conds  imregs{2}.conds...
        imregs{3}.conds  imregs{4}.conds];
    %% LCOALIZER IS RUN 1 and ALL IMAGERY are RUN 2
    regs.runs  = [regslocFS.runs imregs{1}.runs*2 imregs{2}.runs*2 ...
        imregs{3}.runs*2  imregs{4}.runs*2];
   
    %% 4a) Initialize subject
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ; 
    %% 4b) Load all masks, and load the pattern from nifti, masked by each mask individually
    for maskIdx = whichMasks
        maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
        subj = load_spm_mask(subj,    maskfn{maskIdx}, maskFile);
        subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_filenames);
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
     outfile = sprintf('%s/Loc2Shift%d_%dTRsXALLPHASE2_subject%d_%s_%s_%s.mat', outfold, loc2_shiftTRs, loc2_numTRs, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
     save(outfile, 'results', 'maskfn', 'subject', 'class_args', 'imregs');

end