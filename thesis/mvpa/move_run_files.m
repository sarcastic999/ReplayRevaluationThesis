for subject = 1:26    
    baseDirFSL = '/jukebox/norman/reprev/';
    FSLsubDir   = [baseDirFSL 'subj/newS' num2str(subject)  '/'];
    for run = 1:4
        atest    = dir([ FSLsubDir 'NII/prestat_run' num2str(run) '/']);
        feat_dir = atest(1).name;
        run_ima_nifti_dir   = [FSLsubDir 'NII/prestat_run' num2str(run) '/' feat_dir '/'];
        filename   =  [run_ima_nifti_dir 'filtered_func_data.nii']; 
        dest = sprintf('/usr/people/erhee/norman/reprev/Eehpyoung/fsl/runs_data/newS%d/filtered_func_data_run%d.nii',subject,run)
        system(sprintf('cp %s %s',filename, dest));
    end
end
