function [am pm] = Searchmight_FaceMask_Generator()
% Evenly Separate the Labels
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
VALID_SUBJECTS = [5:9 11:23 25:26];
environment_setup;
setenv('LOC2TR','2');
baseDirFSL = '/jukebox/norman/reprev/';
for subject = VALID_SUBJECTS
    FSLsubDir   = [baseDirFSL 'subj/newS' num2str(subject)  '/'];
    maskExt         = {'.img';'.img';'.img'};
    maskfn          = {'face';'scene';'mask'};
    maskNames       = {'face';'scene';'wholebrain'};

    %% MASK
    maskDir     = { [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ];...
                    [ baseDirFSL 'results_spm/newS' num2str(subject)  '/localizer_glm/' ]};


    
    whichMasks      = 3;
    if isempty(getenv('SGE_DATAPATH'))
        datapath = '/jukebox/norman/reprev/Eehpyoung';
    else
        datapath = getenv('SGE_DATAPATH');
    end
    
    outfold = sprintf('%s/Searchmight/InformationMaps',datapath);
    if ~exist(outfold)
        mkdir(outfold);
    end;
    results =[];
    tic
    
    %% load localizer 1
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc/*.feat',subject));
    feat_dir    = lsdir(1).name;
    raw_loc1_filename   = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc/%s/filtered_func_data.nii',subject,feat_dir);

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
    if epiLenTrain<length(regs.conds) % shorten regs
        localizer1_regs.conds = localizer1_regs.conds(:,1:epiLenTrain);
        localizer1_regs.runs  = localizer1_regs.runs(1: epiLenTrain);
    else
        % pad
        localizer1_regs.conds(:, end+1:epiLenTrain) = 0;
        localizer1_regs.runs(end+1:epiLenTrain)     = max(regs.runs);
    end
        
    
    %% first 5 subjects do not have localizer 2
    if subject < 5
        printf('ERROR: SUBJECTS 1~5 DO NOT HAVE LOCALIZER 2');
        return;
    end
    loc2_shiftTRs = 2;
    localizer2_regs = loc2_createRegressor(subject,loc2_shiftTRs);

    %% Load Localizer 2
    lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
    feat_dir = lsdir(1).name;
    raw_loc2_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);
    
    %% 3.c.) combine all NIFTI images
    raw_filenames = {raw_loc1_filename raw_loc2_filename};
    %% 6c) combine the regressors
    clear regs;
    regsloc1FS.conds = localizer1_regs.conds(1:2, :);
    regsloc1FS.runs = localizer1_regs.runs;
    regsloc2FS.conds = localizer2_regs.conds(1:2, :);
    regsloc2FS.runs = localizer2_regs.runs;
    regs.conds = [regsloc1FS.conds regsloc2FS.conds];
    
    %% LCOALIZER IS RUN 1 and ALL IMAGERY are RUN 2
    regs.runs  = [regsloc1FS.runs regsloc2FS.runs*2];
   
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
    subj = create_norest_sel(subj,  'conds');
    subj = create_xvalid_indices(subj, 'runs', ...
        'actives_selname',  'conds_norest', ...
        'ignore_jumbled_runs', true, ...
        'new_selstem','runs_norest_xval');
    subj = zscore_runs(subj,  'epi3', 'runs', ...
        'actives_selname',  'conds_norest', ...
        'ignore_jumbled_runs', true);


    % get data into a #TRs x #voxels matrix, and also mask
    patIdx = 2; % w.r.t subj datastructure (z-scored)
    maskIdx = 1; % w.r.t subj datastructure
    TRdata = subj.patterns{patIdx}.mat';
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

%     for ib = 1:nBlocks
%       range = blockBegins(ib):blockEnds(ib);
%       examples(ib,:)  = mean(TRdata(range,:),1);
%       labels(ib)      = TRlabels(blockBegins(ib));
%       labelsGroup(ib) = TRlabelsGroup(blockBegins(ib));
%     end

    %% Visible Face VS Invisible Face
    examples = TRdata; labels = TRlabels; labelsGroup = TRlabelsGroup;
    % Kill all faces
    labels(find(labels==1))=0;
    
    % nuke examples with label 0
    indicesToNuke = find(labels == 0);
    examples(indicesToNuke,:)  = [];
    labels(indicesToNuke)      = [];
    labelsGroup(indicesToNuke) = [];

    % Segregate the Faces
    labels(find(labelsGroup==1)) = 1;
    % LOOCV
    labelsGroup = 1:numel(labelsGroup);
    
    % create a meta structure (see README.datapreparation.txt and demo.m for more details about this)
    metaFolder = sprintf('./Searchmight/Meta');
    metaFilename = sprintf('%s/Subject%d_%s.mat',metaFolder, subject, maskNames{maskIdx});
    if ~exist(metaFolder)
        mkdir metaFolder;
    end
    if ~exist(metaFileName)
        meta = createMetaFromMask(mask);
        save(metaFileName, 'meta');
    else
        load(metaFileName);
    end
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
    figure;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(volume(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      %if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    hc=suptitle(sprintf('Visible VS Invisible Scene Accuracy map for subject %d',subject)); set(hc,'FontSize',8);
    
    Fmask = zeros(dimx,dimy,dimz);
    Fmask(meta.indicesIn3D(find(pm<=IDThresh))) = 1;
    
    figure;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(Fmask(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      %if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    hc=suptitle(sprintf('Visible VS Invisible Scene Significant Voxels (FDR) map for subject %d',subject)); set(hc,'FontSize',8);
%     %%--------------------------------Multiples----------------------------------------
%         maps = {'voxelwiseGNB','searchlightGNB','searchlightLDA_shrinkage','searchlightLDA_ridge','searchlightSVM_linear','searchlightSVM_quadratic','searchlightSVM_rbf'};
%         [amm, pmm] = computeManyMapsFromOneDataset(examples, labels, labelsGroup', meta,'maps',maps);
%         for idx = 1:numel(maps)
%             [thresholdID,thresholdN] = computeFDR(pmm(idx,:),FDR);
%             binaryMap = pmm(idx,:) <= thresholdID; % thresholded map
%             % quick plot of the results
%             clf; nrows = ceil(sqrt(dimz)); ncols = nrows;
%             volume = repmat(NaN,[dimx dimy dimz]);
%             % place accuracy map in a 3D volume, using the vectorized indices of the mask in meta
%             volume(meta.indicesIn3D) = amm(idx,:);
%             figure;
%             for iz = 1:dimz
%               subplot(nrows,ncols,iz);
%               imagesc(volume(:,:,iz)',[0 1]); axis square;
%               set(gca,'XTick',[]); set(gca,'YTick',[]);
%               if iz == 1; hc=title('accuracy map for mask'); set(hc,'FontSize',8); end
%               if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
%             end
%         end
    %     
    % %%----------------------------------------------------------------------------------
    % %% SAVE RESULTS
    %outfile = sprintf('%s/FSmask_gnb_subject%d.mat', outfold, subject) ;
    %save(outfile, 'am', 'pm', 'FSmask');
end;
     
     

