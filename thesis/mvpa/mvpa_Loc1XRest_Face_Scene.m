% does cross validation decoding on the localizer
%% a: no noise reval berlin
%% b: noise no reval london
%% c: noise reval paris             EXPECTED MAX REPLAY
%% d: no noise no reval kyoto       EXPECTED MIN REPLAY

%% rest onsets: NEWonset_MDP_regs_restonly; 
function [ results ] = mvpa_Loc1XRest_Face_Scene( subject, class_args )
    baseDirFSL = '/jukebox/norman/reprev/';
    
    maskExt         = {'.img';'.img';'.nii'; '.nii'; '.img'; '.nii'; '.nii';  };
    maskfn          = {'face';'scene'; 'FS_mask' ; 's8FSmask'; 'joint_func_roi'; 'MASK_FACE_SCENE'};

    whichMasks      = 1:2;
    if isempty(getenv('SGE_DATAPATH'))
        datapath = '/usr/people/erhee/thesis/mvpa'; %default data path
    else
        datapath = getenv('SGE_DATAPATH');
    end
    
    outfold = sprintf('%s/MVPA_Rest_Face_Scene',datapath);
    if ~exist(outfold)
        mkdir(outfold);
    end;
    results =[];
    tic
    s = subject;
    %% %
    regs_folder     = [baseDirFSL 'behavioral/newS' num2str(s) '/onsets/']; %[onsdir 'newregs/'];
    reg_loc1_file   = 'NEWregLoc_RepReval_3CAT_SPM_shift3_dur3_1run';
    regsFile_train  = [regs_folder reg_loc1_file '.mat'];
    
    
    %% %%%%%%%% TEST DATA %%%%%%%%%%%%%%%%%%%%
    if exist(regsFile_train) % only for the subjects who have the regs
        runtime     = datestr(now);
        FSLsubDir   = [baseDirFSL 'subj/newS' num2str(s)  '/'];
        %% MASK
        maskDir     = { [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ];...
                        [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ];...
                        [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ]};

        subName     = ['newS' num2str(s)]; 
        %% NIFTI LOCALIZER
        a           = dir([ FSLsubDir 'NII/prestat_loc/']);
        feat_dir    = a(1).name;
        run_nifti_dir       = [FSLsubDir 'NII/prestat_loc/' feat_dir '/'];
        raw_loc_filenames   = [run_nifti_dir 'filtered_func_data.nii']; % XXX why was it filtered_func_data??? XX %cellstr(spm_select('FPList', run_nifti_dir, filter));
        
        %% REGS LOCALIZER training set
        load(regsFile_train);
        regsloc = regs;
        %% pad volumes
        TrainVOl    = spm_read_hdr(raw_loc_filenames);
        epiLenTrain = TrainVOl.dime.dim(5); %checkLengthLoc.patterns{1}.matsize(2); %length(raw_loc_filenames);
        clear TrainVOl;
        if epiLenTrain<length(regs.conds) % shorten regs
            regsloc.conds = regs.conds(:,1:epiLenTrain);
            regsloc.runs  = regs.runs(1: epiLenTrain);
        else
            % padd
            regsloc = regs;
            regsloc.conds(:, end+1:epiLenTrain) = 0;
            regsloc.runs(end+1:epiLenTrain)     = max(regs.runs);
        end
        %% 6.a.2.) REDUCE THE LOCALIZER CONDITIONS TO FACE AND SCENE
        regslocFS.conds = regsloc.conds(1:2, :); % getting rid of object, i.e. 3rd row
        regslocFS.runs  = regsloc.runs;
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% MDP:: COMBINE ALL RELEVANT RUNS AND ADD THEM TO THE END OF THE FILE
        MDPfolder     = [ baseDirFSL 'behavioral/newS' num2str(s) '/onsets/restOnsets/']; %'/MDPonsets/'];
        
        for run = 1:4
            %% 1. c) MDP REST current run :: test set
            reg_file_name = 'REST_reprev';
            regsFile_test = [ MDPfolder reg_file_name 'run' num2str(run) '_shift3.mat'];
            
            
            %% 2.b) MDP NIFTIs repRev runs
            atest    = dir([ FSLsubDir 'NII/prestat_run' num2str(run) '/']);
            feat_dir = atest(1).name; %'/+.feat/' or one with the most ++, aka the newest
            run_ima_nifti_dir   = [FSLsubDir 'NII/prestat_run' num2str(run) '/' feat_dir '/']; %[subDir '/data/run' num2str(run) '/'];
            raw_ima_filenames{run}   =  [run_ima_nifti_dir 'filtered_func_data.nii']; %cellstr(spm_select('FPList', run_ima_nifti_dir, filter));
            
            %% 5) LOAD MDP REGSFILES
            %% **** be careful about end+1 and also what goes into epilen
            regsloc.conds(:, end+1:epiLenTrain) = 0;
            regsloc.runs(1) = 1;
            regsloc.runs( end+1:epiLenTrain)     = max(regsloc.runs); % 10
            
            % c) clear regs to avoid misakes/overwrites
            clear regs;
            %% b) test set
            load(regsFile_test);
            
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
        raw_filenames = {raw_loc_filenames ;    raw_ima_filenames{1} ;...
            raw_ima_filenames{2};...
            raw_ima_filenames{3};...
            raw_ima_filenames{4}};
        %% 6c) combine the regressors
        clear regs;
        regs.conds = [regslocFS.conds imregs{1}.conds  imregs{2}.conds...
            imregs{3}.conds  imregs{4}.conds];
        %% LCOALIZER IS RUN 1 and ALL IMAGERY are RUN 2
        %% THIS GIVES IMAGERY EVIDENCE FOR THIS PERSON IN GENERAL!
        regs.runs  = [regslocFS.runs imregs{1}.runs*2 imregs{2}.runs*2 ...
            imregs{3}.runs*2  imregs{4}.runs*2];

        %% 4a) Initialize subject
        subj = init_subj('IM_PM',  subName) ; 
        %% 4b) Load all masks, and load the pattern from nifti, masked by each mask individually
        for maskIdx = whichMasks
            maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
            subj = load_spm_mask(subj,    maskfn{maskIdx}, maskFile);
            subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_filenames);
        end
        
        %% 7) initialize regressors
        subj = init_object(subj,'regressors','conds');
        subj = set_mat(subj, 'regressors', 'conds', regs.conds);
        
        %% 8) define selectors or 'runs'
        subj = init_object(subj, 'selector', 'runs');
        subj = set_mat(subj, 'selector', 'runs', regs.runs);
        
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
                'actives_selname',  'conds_norest', 'ignore_jumbled_runs', true);
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
         outfile = sprintf('%s/Loc1XRest_subject%d_%s_%s_%s.mat', outfold, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
         save(outfile, 'results', 'maskfn', 'subject', 'class_args','imregs');

    end
end