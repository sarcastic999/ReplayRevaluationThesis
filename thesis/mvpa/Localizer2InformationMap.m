function [am pm amm pmm] = Localizer2InformationMap(subject)

% adapted from  
%
%    TUTORIAL_EASY.HTM 
%    This is the sample script for the Haxby et al. (Science, 2001) 8-
%    categories study. See the accompanying TUTORIAL_EASY.HTM, the
%    MVPA manual (MANUAL.HTM) and then TUTORIAL_HARD.HTM.
%
% requires SearchmightToolbox in your path, so
% - addpath(<path to SearchmightToolbox)
% - setupPathsSearchmightToolbox
%
% and also the path you'd need in order to run the MVPA toolbox tutorial
%
    baseDirFSL = '/jukebox/norman/reprev/';
    FSLsubDir   = [baseDirFSL 'subj/newS' num2str(subject)  '/'];
    maskExt         = {'.img';'.img';'.img'};
    maskfn          = {'face';'scene';'mask'};
    maskNames       = {'face';'scene';'wholebrain'};

    whichMasks      = 3;
    if isempty(getenv('SGE_DATAPATH'))
        datapath = '/usr/people/erhee/thesis/mvpa'; %default data path
    else
        datapath = getenv('SGE_DATAPATH');
    end
    
    outfold = sprintf('%s/Searchmight/InformationMaps',datapath);
    if ~exist(outfold)
        mkdir(outfold);
    end;
    results =[];
    tic
    %% first 5 subjects do not have localizer 2
    if subject < 5
        printf('ERROR: SUBJECTS 1~5 DO NOT HAVE LOCALIZER 2');
        return;
    end
    s = subject;
    loc2_shiftTRs = 2;
    localizer_regs = loc2_createRegressor(subject,loc2_shiftTRs);
    runtime     = datestr(now);
    %% MASK
    maskDir     = { [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(s)  '/localizer_glm/' ]};


    %% Load Localizer Volumes
    MDPfolder     = [ baseDirFSL 'behavioral/newS' num2str(s) '/onsets/restOnsets/']; %'/MDPonsets/'];
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
    feat_dir = lsdir(1).name;
    raw_loc_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);
    
    %% 3.c.) combine all NIFTI images
    raw_filenames = {raw_loc_filename};
    %% 6c) combine the regressors
    regslocFS.conds = localizer_regs.conds(1:2, :);
    regslocFS.runs = localizer_regs.runs;
    regs.conds = regslocFS.conds;
    %% LCOALIZER IS RUN 1 and ALL IMAGERY are RUN 2
    regs.runs  = regslocFS.runs;
   
    %% 4a) Initialize subject
    subj = init_subj('IM_PM',  sprintf('newS%d',subject)) ; 
    %% 4b) Load all masks, and load the pattern from nifti, masked by each mask individually
    for maskIdx = whichMasks
        maskFile  = [maskDir{maskIdx}  maskfn{maskIdx} maskExt{maskIdx} ];
        subj = load_spm_mask(subj,    maskNames{maskIdx}, maskFile);
        subj = load_spm_pattern(subj, ['epi'  num2str(maskIdx)], maskNames{maskIdx}, raw_filenames);
    end
    %% 7) initialize regressors
    subj = initset_object(subj,'regressors','conds', regs.conds);

    %% 8) define selectors or 'runs'
    subj = initset_object(subj, 'selector', 'runs', regs.runs);

    %% 9) define condnames
    % XXX CHANGED THIS 2 REFLECT 2 CATEGORIES. CHANGE FOR OBJECT
    condnames = {'faces', 'scenes'};
    subj = set_objfield(subj, 'regressors', 'conds', 'condnames', condnames);

    % get data into a #TRs x #voxels matrix, and also mask
    maskIdx = 1;
    TRdata = subj.patterns{maskIdx}.mat';
    [nTRs,nVoxels] = size(TRdata);

    mask = subj.masks{maskIdx}.mat;
    [dimx,dimy,dimz] = size(mask);

    % create labels for each TR (column vectors)
    TRlabels = sum(subj.regressors{1}.mat .* repmat((1:2)',1,nTRs),1);
    %TRlabels      = sum(regs .* repmat((1:8)',1,nTRs),1)';
    %TRlabelsGroup = runs';
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

    for ib = 1:nBlocks
      range = blockBegins(ib):blockEnds(ib);
      examples(ib,:)  = mean(TRdata(range,:),1);
      labels(ib)      = TRlabels(blockBegins(ib));
      labelsGroup(ib) = TRlabelsGroup(blockBegins(ib));
    end

    % nuke examples with label 0
    indicesToNuke = find(labels == 0);
    examples(indicesToNuke,:)  = [];
    labels(indicesToNuke)      = [];
    labelsGroup(indicesToNuke) = [];
    
    %% Prep Labels for LOOCV - we know there are 12 groups
    labelsGroup(find(labels==1)) = 1:12;
    labelsGroup(find(labels==2)) = 1:12;

    % create a meta structure (see README.datapreparation.txt and demo.m for more details about this)
    meta = createMetaFromMask(mask);

    %
    % run a fast classifier (see demo.m for more details about computeInformationMap)
    %

    FDR = 0.05;
    classifier = 'gnb_searchmight'; % fast GNB

    [am,pm] = computeInformationMap(examples,labels,labelsGroup,classifier,'searchlight', ...
                                    meta.voxelsToNeighbours,meta.numberOfNeighbours);

    % quick plot of the results
    [IDThresh nThresh] = computeFDR(pm,FDR);
    clf; nrows = ceil(sqrt(dimz)); ncols = nrows;
    volume = repmat(NaN,[dimx dimy dimz]);
    % place accuracy map in a 3D volume, using the vectorized indices of the mask in meta
    volume(meta.indicesIn3D) = am;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(volume(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      if iz == 1; hc=title('accuracy map for mask'); set(hc,'FontSize',8); end
      if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    %%------------------------------------------------------------------------
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
        for iz = 1:dimz
          subplot(nrows,ncols,iz);
          imagesc(volume(:,:,iz)',[0 1]); axis square;
          set(gca,'XTick',[]); set(gca,'YTick',[]);
          if iz == 1; hc=title('accuracy map for mask'); set(hc,'FontSize',8); end
          if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
        end
    end
    
%%----------------------------------------------------------------------------------
%% SAVE RESULTS
  outfile = sprintf('%s/Loc2_subject%d.mat', outfold, subject) ;
  save(outfile, 'amm', 'pmm', 'maps');


     
     
     
     

