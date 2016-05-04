function fMRIMeasure = ensemble_mvpa_Loc1XRest()
behavioralMeasure = [
    0.2	-1.0	1.0	0
    0.2	-1.0	0.0	-1.0
    0.2	-1.0	0	0.0
    0.0	-0.466666666667	0	0.0
    0	-0.8	0.0	-1.0
    0.0	0	1.0	-0.8
    0.0666666666667	0	0.0	-0.55
    0	0	0.3	0.0666666666667
    -1.0	0	0	-1.0
    0.2	-1.0	-0.8	0
    0.2	-1.0	-0.333333333333	0
    0.2	-1.0	0.4	0
    0.2	-1.0	-0.75	0
    0.2	-0.8	-0.8	0
    0.0	-1.0	0.0	-0.55
    0.2	-0.666666666667	0.0	0
    0.4	-1.0	-0.8	0
    0.2	-0.8	0.0	0
    0.4	0	0.0	0.0666666666667
    0.4	-0.1	0.4	-0.1
    0.466666666667	-0.05	0.666666666667	0.1
    0.0	0	-0.25	0.2
    -0.1	-0.75	0.0	0
    -0.25	0.0	0.0	0.2
    -0.25	-0.8	0.0	-1.0
    0.0	0.0	0.0	0
    ];
    environment_setup;
    rf = 1;
    VALID_SUBJECTS = [1:9 11:23 25:26];
    outfold = '/usr/people/erhee/thesis/mvpa/ensemble_MVPA_Rest_Face_Scene';
    if ~exist(outfold)
        mkdir(outfold);
    end
    
    baseDirFSL = '/jukebox/norman/reprev/';
    
    maskExt         = {'.img';'.img';'.nii'; '.nii'; '.img'; '.nii'; '.nii';  };
    maskfn          = {'face';'scene'; 'FS_mask' ; 's8FSmask'; 'joint_func_roi'; 'MASK_FACE_SCENE'};

    whichMasks      = 1:2;

    for s = VALID_SUBJECTS
        if(rf)
            outfile = sprintf('%s/Loc1XRest_subject%d_%s.mat', outfold, s, 'RandomForest500Trees');
        else
            outfile = sprintf('%s/Loc1XRest_subject%d_%s.mat', outfold, s, 'AdaBoost500Trees_LearnRate1');
        end

        if ~exist(outfile)
            regs_folder     = [baseDirFSL 'behavioral/newS' num2str(s) '/onsets/']; %[onsdir 'newregs/'];
            reg_loc1_file   = 'NEWregLoc_RepReval_3CAT_SPM_shift3_dur3_1run';
            regsFile_train  = [regs_folder reg_loc1_file '.mat'];

            if exist(regsFile_train) % only for the subjects who have the regs
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
                regslocFS.conds = regsloc.conds(1:2, :); % getting rid of object, i.e. 3rd row
                regslocFS.runs  = regsloc.runs;
                MDPfolder     = [ baseDirFSL 'behavioral/newS' num2str(s) '/onsets/restOnsets/'];

                for run = 1:4
                    %% 1. c) MDP REST current run :: test set
                    reg_file_name = 'REST_reprev';
                    regsFile_test = [ MDPfolder reg_file_name 'run' num2str(run) '_shift3.mat'];


                    %% 2.b) MDP NIFTIs repRev runs
                    atest    = dir([ FSLsubDir 'NII/prestat_run' num2str(run) '/']);
                    feat_dir = atest(1).name; %'/+.feat/' or one with the most ++, aka the newest
                    run_ima_nifti_dir   = [FSLsubDir 'NII/prestat_run' num2str(run) '/' feat_dir '/']; %[subDir '/data/run' num2str(run) '/'];
                    raw_ima_filenames{run}   =  [run_ima_nifti_dir 'filtered_func_data.nii']; %cellstr(spm_select('FPList', run_ima_nifti_dir, filter));
                    regsloc.conds(:, end+1:epiLenTrain) = 0;
                    regsloc.runs(1) = 1;
                    regsloc.runs( end+1:epiLenTrain)     = max(regsloc.runs);
                    clear regs;
                    load(regsFile_test);

                    TestVol     = spm_read_hdr(raw_ima_filenames{run});
                    epiLentest  = TestVol.dime.dim(5);

                    clear TestVol;
                    if epiLentest<length(regs.conds) 
                        imregs{run}.conds = regs.conds(:,1:epiLentest);
                        imregs{run}.runs  = regs.runs(1: epiLentest);
                    else
                        imregs{run} = regs;
                        imregs{run}.conds(:, end+1:epiLentest) = 0;
                        imregs{run}.runs(end+1:epiLentest)     = max(imregs{run}.runs);
                    end

                end
                raw_filenames = {raw_loc_filenames ;    raw_ima_filenames{1} ;...
                    raw_ima_filenames{2};...
                    raw_ima_filenames{3};...
                    raw_ima_filenames{4}};
                clear regs;
                regs.conds = [regslocFS.conds imregs{1}.conds  imregs{2}.conds...
                    imregs{3}.conds  imregs{4}.conds];
                regs.runs  = [regslocFS.runs imregs{1}.runs*2 imregs{2}.runs*2 ...
                    imregs{3}.runs*2  imregs{4}.runs*2];
                subj = init_subj('IM_PM',  subName) ; 
                for maskIdx = whichMasks
                    maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
                    subj = load_spm_mask(subj,    maskfn{maskIdx}, maskFile);
                    subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskfn{maskIdx}, raw_filenames);
                end

                subj = init_object(subj,'regressors','conds');
                subj = set_mat(subj, 'regressors', 'conds', regs.conds);
                subj = init_object(subj, 'selector', 'runs');
                subj = set_mat(subj, 'selector', 'runs', regs.runs);
                condnames = {'faces', 'scenes'} %, 'objects'};
                subj = set_objfield(subj, 'regressors', 'conds', 'condnames', condnames);
                subj = create_norest_sel(subj,  'conds');
                subj = create_xvalid_indices(subj, 'runs', ...
                    'actives_selname',  'conds_norest', ...
                    'ignore_jumbled_runs', true, ...
                    'new_selstem','runs_norest_xval');

                %% 13) run mvpa for each mask
                for maskIdx = whichMasks % 1:length(maskfn);
                    subj = zscore_runs(subj,  ['epi'  num2str(maskIdx)], 'runs', ...
                        'actives_selname',  'conds_norest', 'ignore_jumbled_runs', true);
                end
                summarize(subj, 'display_groups', false)
                nTrees = 500;
                %% Face, Training on Loc 1 Testing on Loc 2 -- this for resting period test
                mask = 1;
                testData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 2));
                trainData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 1));
                trainlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 1));
                testlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 2));
                testData = testData';
                trainData = trainData';

                if(rf)
                    %% Random Forests
                    B = TreeBagger(nTrees,trainData,trainlabels, 'Method', 'classification');
                    f_rfresults_char = B.predict(testData);
                    for ind = 1:numel(f_rfresults_char);
                        f_rfresults(ind) = str2num(f_rfresults_char{ind});
                    end
                else
                    %% AdaBoost
                    ada = fitensemble(trainData,trainlabels,'AdaBoostM1',...
                        nTrees,'Tree','LearnRate',0.1);
                    f_adaresults = ada.predict(testData);
                end
                %% Scene, Training on Loc 1 Testing on Loc 2 -- this for resting period test
                mask = 2;
                testData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 2));
                trainData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 1));
                trainlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 1));
                testlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 2));
                testData = testData';
                trainData = trainData';

                if(rf)
                    %% Random Forests
                    B = TreeBagger(nTrees,trainData,trainlabels, 'Method', 'classification');
                    s_rfresults_char = B.predict(testData);
                    for ind = 1:numel(s_rfresults_char);
                        s_rfresults(ind) = str2num(s_rfresults_char{ind});
                    end
                else
                    %% AdaBoost
                    ada = fitensemble(trainData,trainlabels,'AdaBoostM1',...
                        nTrees,'Tree','LearnRate',0.1);
                    s_adaresults = ada.predict(testData);
                end
                %% Load Conditions Order
                mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
                conditions_filename = [ mvpa_FFAPPA2cat 'S' num2str(s) '_loc1Xrest.mat'] ;
                load(conditions_filename);
                mdp_conditions_order = meanRunMdp(1,:);
                mdp_names = {'--' 'r-' '-n' 'rn'};
                disp(mdp_names(mdp_conditions_order));

                %% SAVE RESULTS
                if(rf)
                    save(outfile,'mdp_conditions_order', 'f_rfresults', 's_rfresults');
                else
                    save(outfile,'mdp_conditions_order', 'f_adaresults', 's_adaresults');
                end
            end
        end
        clear estimates;
        clear mdp_conditions_order;
        load(outfile);
        
        %% Output Dot Products
        for run = 1:4
            startIndex = (run-1)*45 + 1;
            endIndex = startIndex + 44;
            if(rf)
                f_vector = f_rfresults(startIndex:endIndex);
                s_vector = s_rfresults(startIndex:endIndex);
            else
                f_vector = f_adaresults(startIndex:endIndex);
                s_vector = s_adaresults(startIndex:endIndex);
            end
            m1 = dot(f_vector,s_vector);
            m2 = sum(f_vector) + sum(s_vector);
            estimates(run) = m1 + m2;
        end
        
        
        disp(estimates);
        fMRIMeasure(find(VALID_SUBJECTS==s),:) = estimates(mdp_conditions_order);
    end
    disp(fMRIMeasure);
    
    validFMRIMeasure = fMRIMeasure;
    validBehavioralMeasure = behavioralMeasure(VALID_SUBJECTS,:);
    
    revalFMRIMean    = [ mean(validFMRIMeasure(:,   [1 3]) , 2) mean(validFMRIMeasure(:,   [2 4]) , 2) ];
    revalBehavioralMean  = [ mean(validBehavioralMeasure(:, [1 3]) , 2) mean(validBehavioralMeasure(:, [2 4]) , 2) ];
    [RHO_NoReval,PVAL_NoReval] = corr(revalFMRIMean(:,1), revalBehavioralMean(:, 1), 'type', 'Spearman' , 'tail', 'right')
    [RHO_Reval,PVAL_Reval] = corr(revalFMRIMean(:,2), revalBehavioralMean(:, 2), 'type', 'Spearman' , 'tail', 'left')

end
