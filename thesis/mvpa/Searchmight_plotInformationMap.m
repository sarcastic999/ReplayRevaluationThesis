function Searchmight_plotInformationMap(subject)%% OUTPUT PATH
    if isempty(getenv('SGE_DATAPATH'))
        datapath = '/jukebox/norman/reprev/Eehpyoung'; %default data path
    else
        datapath = getenv('SGE_DATAPATH');
    end
    brain_mask_size = 'SM';
    outfold = sprintf('%s/Searchmight/InformationMaps',datapath);
    file = sprintf('%s/RevalVSNoReval_%smask_subject%d.mat', outfold, brain_mask_size, subject);
    load(file);
    
    metaFolder = sprintf('%s/Searchmight/Meta',datapath);
    metaFilename = sprintf('%s/Subject%d_%s.mat',metaFolder, subject, brain_mask_size);
    load(metaFilename);
    
    dimx = meta.dimx; dimy = meta.dimy; dimz = meta.dimz;
    %% Condition Order
    mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
    file1 = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
    load(file1, 'meanRunMdp');
    mdp_conditions_order = meanRunMdp(1,:);
    
    
    % quick plot of the results
    bonferroniThresh = 0.05/meta.nVoxels;
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
    hc=suptitle(sprintf('gnb accuracy map for subject %d, [%d %d %d %d]', subject,mdp_conditions_order(1), mdp_conditions_order(2), mdp_conditions_order(3), mdp_conditions_order(4)));
    set(hc,'FontSize',8);
    Fmask = zeros(dimx,dimy,dimz);
    Fmask(meta.indicesIn3D(find(pm<=bonferroniThresh))) = 1;

    figure;
    for iz = 1:dimz
      subplot(nrows,ncols,iz);
      imagesc(Fmask(:,:,iz)',[0 1]); axis square;
      set(gca,'XTick',[]); set(gca,'YTick',[]);
      %if iz == dimz; hc=colorbar('vert'); set(hc,'FontSize',8); end
    end
    hc=suptitle(sprintf('gnb bonferroni %f p-map for subject %d', bonferroniThresh, subject)); set(hc,'FontSize',8);
end

