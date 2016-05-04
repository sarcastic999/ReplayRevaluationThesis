function [am pm maps] = Searchmight_NoiseVSNoNoise_Mask_Generator()

VALID_SUBJECTS = [1:9 11:23 25:26];
environment_setup;
brain_mask_size = 'SM';
block_trials = 0;
baseDirFSL = '/jukebox/norman/reprev/';

%% OUTPUT PATH
if isempty(getenv('SGE_DATAPATH'))
    datapath = '/jukebox/norman/reprev/Eehpyoung'; 
else
    datapath = getenv('SGE_DATAPATH');
end
outfold = sprintf('%s/Searchmight/InformationMaps',datapath);
if ~exist(outfold)
    mkdir(outfold);
end;
for subject = VALID_SUBJECTS
    outfile = sprintf('%s/NoiseVSNoNoise_%smask_subject%d.mat', outfold, brain_mask_size, subject);
    if exist(outfile)
        %continue;
    end
    
    maskExt         = {'.img'};
    maskfn          = {'mask'};
    maskNames       = {'wholebrain'};
    maskDir         = { [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ]};
    whichMasks      = 1;
    MDPfolder     = [ baseDirFSL 'behavioral/newS' num2str(subject) '/onsets/restOnsets/']; %'/MDPonsets/'];
    for run = 1:4
        %% 1. c) MDP REST current run :: test set
        reg_file_name = 'REST_reprev';
        regsFile_test = [ MDPfolder reg_file_name 'run' num2str(run) '_shift3.mat'];

        FSLsubDir   = [baseDirFSL 'subj/newS' num2str(subject)  '/'];
        %% 2.b) MDP NIFTIs repRev runs
        atest    = dir([ FSLsubDir 'NII/prestat_run' num2str(run) '/']);
        feat_dir = atest(1).name; %'/+.feat/' or one with the most ++, aka the newest
        run_ima_nifti_dir   = [FSLsubDir 'NII/prestat_run' num2str(run) '/' feat_dir '/']; %[subDir '/data/run' num2str(run) '/'];
        raw_ima_filenames{run}   =  [run_ima_nifti_dir 'filtered_func_data.nii']; %cellstr(spm_select('FPList', run_ima_nifti_dir, filter));
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
    
    %% Condition Order
    mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
    file1 = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
    load(file1, 'meanRunMdp');
    mdp_conditions_order = meanRunMdp(1,:);
    
    raw_filenames = {raw_ima_filenames{1} ;...
    raw_ima_filenames{2};...
    raw_ima_filenames{3};...
    raw_ima_filenames{4}};

    %% combine the regressors
    clear regs;
    
    regs.conds = [imregs{1}.conds  imregs{2}.conds...
        imregs{3}.conds  imregs{4}.conds];
    regs.runs  = [imregs{1}.runs imregs{2}.runs ...
        imregs{3}.runs  imregs{4}.runs];
    %% INITIALIZE SUBJECT
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ; 
    for maskIdx = whichMasks
        maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
        subj = load_spm_mask(subj,    maskNames{maskIdx}, maskFile);
        subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskNames{maskIdx}, raw_filenames);
    end
    
    subj = initset_object(subj,'regressors','conds', regs.conds);
    subj = initset_object(subj, 'selector', 'runs', regs.runs);
    subj = create_norest_sel(subj,  'conds');
    subj = zscore_runs(subj,  'epi1', 'runs', ...
        'actives_selname',  'conds_norest', ...
        'ignore_jumbled_runs', true);

    
    
    %% PREP PARAMETERS FOR SEARCHLIGHT
    % get data into a #TRs x #voxels matrix, and also mask
    patIdx = 2; % w.r.t subj datastructure (z-scored)
    maskIdx = 1; % w.r.t subj datastructure
    TRdata = subj.patterns{patIdx}.mat';
    [nTRs,nVoxels] = size(TRdata);
    mask = subj.masks{maskIdx}.mat;
    [dimx,dimy,dimz] = size(mask);

    %% Prepare data for searchlight.
    % Noise are indices 3 and 4.
    imregs{find(mdp_conditions_order==3)}.conds = imregs{find(mdp_conditions_order==3)}.conds * 2;
    imregs{find(mdp_conditions_order==4)}.conds = imregs{find(mdp_conditions_order==4)}.conds * 2;
    % Cross Validation, [No Reval No Noise && Reval Noise] VS [Reval No
    % Noise && No Reval Noise]
    imregs{find(mdp_conditions_order==1)}.runs = imregs{find(mdp_conditions_order==1)}.runs * 2;
    imregs{find(mdp_conditions_order==4)}.runs = imregs{find(mdp_conditions_order==4)}.runs * 2;

    
    
    % create labels for each TR (column vectors)
    TRlabels = sum([imregs{1}.conds  imregs{2}.conds...
        imregs{3}.conds  imregs{4}.conds]);
    TRlabelsGroup = [imregs{1}.runs imregs{2}.runs ...
        imregs{3}.runs  imregs{4}.runs];
    

    %
    % turn each block into an example, and convert labels
    %

    % binary mask for beginning and end of blocks (task or fixation)
    TRmaskBlockBegins = ([1;diff(TRlabels)'] ~= 0); 
    TRmaskBlockEnds   = ([diff(TRlabels)';1] ~= 0);

    % average blocks (we will get rid of 0-blocks afterwards)
    % (silly average of all images, without thinking of haemodynamic response)
    % to convert them into examples (and create labels and group labels)

    % figure out how many blocks and what TRs they begin and end at
    nBlocks = sum(TRmaskBlockBegins);
    blockBegins = find(TRmaskBlockBegins);
    blockEnds   = find(TRmaskBlockEnds);

    % create one example per block and corresponding labels
    labels      = zeros(nBlocks,1); % condition
    labelsGroup = zeros(nBlocks,1); % group (usually run)
    examples    = zeros(nBlocks,nVoxels); % per-block examples
    if block_trials
        for ib = 1:nBlocks
           range = blockBegins(ib):blockEnds(ib);
           examples(ib,:)  = mean(TRdata(range,:),1);
           labels(ib)      = TRlabels(blockBegins(ib));
           labelsGroup(ib) = TRlabelsGroup(blockBegins(ib));
        end
    else
        examples = TRdata;
        labels = TRlabels;
        labelsGroup = TRlabelsGroup;
    end    

%    examples = TRdata; labels = TRlabels; labelsGroup = TRlabelsGroup;
    % nuke examples with label 0
    indicesToNuke = find(labels == 0);
    examples(indicesToNuke,:)  = [];
    labels(indicesToNuke)      = [];
    labelsGroup(indicesToNuke) = [];
    
    % create a meta structure (see README.datapreparation.txt and demo.m for more details about this)
    metaFolder = sprintf('./Searchmight/Meta');
    metaFilename = sprintf('%s/Subject%d_%s.mat',metaFolder, subject, brain_mask_size);
    if ~exist(metaFolder)
        mkdir(metaFolder);
    end
    if ~exist(metaFilename)
        meta = createMetaFromMask(mask);
        save(metaFilename, 'meta');
    else
        load(metaFilename);
    end

    %
    % run a fast classifier (see demo.m for more details about computeInformationMap)
    %

    FDR = 0.1;
    classifier = 'gnb_searchmight'; % fast GNB

    [am,pm] = computeInformationMap(examples,labels,labelsGroup,classifier,'searchlight', ...
                                    meta.voxelsToNeighbours,meta.numberOfNeighbours);

    % quick plot of the results
    [IDThresh nThresh] = computeFDR(pm,FDR);
    bonferroniThresh = 0.05/nVoxels;
    nrows = ceil(sqrt(dimz)); ncols = nrows;
    volume = repmat(NaN,[dimx dimy dimz]);
    % place accuracy map in a 3D volume, using the vectorized indices of the mask in meta
    volume(meta.indicesIn3D) = am;
    figure;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(volume(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      %if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    hc=suptitle(sprintf('searchlight gnb accuracy map for subject %d', subject)); set(hc,'FontSize',8);
    
    Fmask = zeros(dimx,dimy,dimz);
    Fmask(meta.indicesIn3D(find(pm<=bonferroniThresh))) = 1;
    
    figure;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(Fmask(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      %if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    hc=suptitle(sprintf('searchlight gnb bonferroni %f p-map for subject %d', bonferroniThresh, subject)); set(hc,'FontSize',8);
    save(outfile, 'am', 'pm', 'classifier', 'labels', 'labelsGroup');
end;
     
     

