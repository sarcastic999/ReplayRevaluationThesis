function [am pm maps] = Searchmight_Loc2_FaceMask_Generator()

VALID_SUBJECTS = [5:9 11:23 25:26];
environment_setup;
brain_mask_size = 'LG';
block_trials = 1;
setenv('LOC2TR','2'); % Localizer 2, use only first 2 TRs of TR triplets.
baseDirFSL = '/jukebox/norman/reprev/';

%% OUTPUT PATH
if isempty(getenv('SGE_DATAPATH'))
    datapath = '/jukebox/norman/reprev/Eehpyoung'; %default data path
else
    datapath = getenv('SGE_DATAPATH');
end
outfold = sprintf('%s/Searchmight/InformationMaps',datapath);
if ~exist(outfold)
    mkdir(outfold);
end;
for subject = VALID_SUBJECTS
    
    if block_trials
        outfile = sprintf('%s/Loc2_blocked_FS_%smask_subject%d.mat', outfold, brain_mask_size, subject) ;
    else
        outfile = sprintf('%s/Loc2_unblocked_FS_%smask_subject%d.mat', outfold, brain_mask_size, subject) ;
    end
    if exist(outfile)
        continue;
    end
    
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
    feat_dir = lsdir(1).name;
    %% MASK PARAMS
    if strcmp(brain_mask_size, 'LG') == 1
        maskExt         = {'.nii.gz'};
        maskfn          = {'mask'};
        maskNames       = {'wholebrain'};
        %maskDir         = { [ baseDirFSL 'results_spm/newS' num2str(subject)  '/loc2_glm/' ]};
        maskDir = {sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/',subject,feat_dir)};
    else
        maskExt         = {'.img'};
        maskfn          = {'mask'};
        maskNames       = {'wholebrain'};
        maskDir         = { [ baseDirFSL 'results_spm/newS' num2str(subject)  '/loc2_glm/' ]};
    end
    whichMasks      = 1;
    
    %% LOAD LOCALIZER 2 DATA
    if subject < 5
        printf('ERROR: SUBJECTS 1~5 DO NOT HAVE LOCALIZER 2');
        return;
    end
    % Load Data
    raw_loc2_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);
    % Load Data Labels
    loc2_shiftTRs = 2;
    localizer2_regs = loc2_createRegressor(subject,loc2_shiftTRs);
    clear regs;
    regsloc2FS.conds = localizer2_regs.conds(1:2, :);
    regsloc2FS.runs = localizer2_regs.runs;
    regs.conds = [regsloc2FS.conds];
    regs.runs  = [regsloc2FS.runs];
    raw_filenames = {raw_loc2_filename};
    
    %% INITIALIZE SUBJECT
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ; 
    for maskIdx = whichMasks
        maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
        subj = load_spm_mask(subj,    maskNames{maskIdx}, maskFile);
        subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskNames{maskIdx}, raw_filenames);
    end
    subj = initset_object(subj,'regressors','conds', regs.conds);
    subj = initset_object(subj, 'selector', 'runs', regs.runs);
    condnames = {'faces', 'scenes'};
    subj = set_objfield(subj, 'regressors', 'conds', 'condnames', condnames);
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

    % create labels for each TR (column vectors)
    TRlabels = sum(subj.regressors{1}.mat .* repmat((1:2)',1,nTRs),1);
    TRlabelsGroup = subj.selectors{1}.mat';

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

    labelsGroup(find(labels==1)) = 1:count(find(labels==1));
    labelsGroup(find(labels==2)) = 1:count(find(labels==2));
    
    
    % create a meta structure (see README.datapreparation.txt and demo.m for more details about this)
    metaFolder = sprintf('./Searchmight/Meta');
    metaFilename = sprintf('%s/Subject%d_Loc%d_%s.mat',metaFolder, subject, 2, brain_mask_size);
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
    clf; nrows = ceil(sqrt(dimz)); ncols = nrows;
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
    hc=suptitle(sprintf('gnb accuracy map for subject %d', subject)); set(hc,'FontSize',8);
    
    Fmask = zeros(dimx,dimy,dimz);
    Fmask(meta.indicesIn3D(find(pm<=IDThresh))) = 1;
    
    figure;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(Fmask(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      %if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    hc=suptitle(sprintf('gnb FDR 0.1 p-map for subject %d', subject)); set(hc,'FontSize',8);
    %%--------------------------------Multiples----------------------------------------
        maps = {'voxelwiseGNB','searchlightGNB','searchlightLDA_shrinkage','searchlightLDA_ridge','searchlightSVM_linear','searchlightSVM_quadratic','searchlightSVM_rbf'};
        [amm, pmm] = computeManyMapsFromOneDataset(examples, labels, labelsGroup, meta,'maps',maps);
        for idx = 1:numel(maps)
            [thresholdID,thresholdN] = computeFDR(pmm(idx,:),FDR);
            binaryMap = pmm(idx,:) <= thresholdID; % thresholded map
            % quick plot of the results
            clf; nrows = ceil(sqrt(dimz)); ncols = nrows;
            volume = repmat(NaN,[dimx dimy dimz]);
            % place accuracy map in a 3D volume, using the vectorized indices of the mask in meta
            volume(meta.indicesIn3D) = amm(idx,:);
            figure;
            for iz = 1:dimz
              subplot(nrows,ncols,iz);
              imagesc(volume(:,:,iz)',[0 1]); axis square;
              set(gca,'XTick',[]); set(gca,'YTick',[]);
              if iz == 1; hc=title(sprintf('%s accuracy map for subject', maps{idx})); set(hc,'FontSize',8); end
              if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
            end
        end
    %     
    % %%----------------------------------------------------------------------------------
    % %% SAVE RESULTS
    am = [amm;am];
    pm = [pmm;pm];
    maps{8} = 'gnb_searchmight';
    save(outfile, 'am', 'pm', 'maps', 'labels', 'labelsGroup', 'meta');
end;
     
     

