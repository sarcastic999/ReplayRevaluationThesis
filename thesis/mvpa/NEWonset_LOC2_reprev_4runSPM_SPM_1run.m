%% This file generates onsets MVPA style-- choose which type of inset
%  PULSEkeytime
function NEWonset_localizer_reprev_4runSPM_SPM_1run()
%localizer_LR_regs_FacScn_1run() %GENERAL_localizer_onsetes()
clear all;
baseDirFSL      =  '~/norman/reprev/';%      '/Volumes/cohen-2/Ida/IM_replayReval/';
TR                      = 2.08;
%% OUTPUT FILE NAME
reg_file_name = 'NEWregLoc2_RepReval_2CAT_SPM'; % [subj{s}   'regLocalizer_3CAT_oct']

shift_TRs      = 0;

for s = 5:26 %1:23
    
    regs=[];
    in_dir   = [baseDirFSL  'behavioral/newS' num2str(s) '/']; %'onsets/' subj{s} '/'];
    if ~exist([ in_dir 'loc2.mat'])
        s
    end
    load( [ in_dir 'loc2.mat']);
    
    PULSEkeytime = pulse.PULSEkeytime; %localizer.sonsets.localizer_inst.StimulusOnsetTime;
    %% output folder
    onsdir = [in_dir 'onsets/' ];; %[basedir subj{s} '/onsets/'];
    if ~exist(onsdir) mkdir(onsdir); end
    
    ima_index = localizer.allimage_indices ; %localizer.block_juxt(run,trial); %localizer.allimage_indices(run, trial); % XXXXX CHANGE THIS FOR RANDOMIZATION
    inds_flattened = [ima_index(1,:), ima_index(2,:)];
    faceind     = find(inds_flattened<7);
    sceneind    = find(inds_flattened>6);
    
    allons      = localizer.starttimes;
    %% this gives us shifted volumes, also ceil
    ons_shifted_rows =  ceil((allons -  PULSEkeytime )/TR)  + shift_TRs;
    ons_shifted = [ons_shifted_rows(1,:) ons_shifted_rows(2,:)];
    
    faceons     = ons_shifted(faceind); % dur 5
    sceneons    = ons_shifted(sceneind); % dur 5
    restons     = ons_shifted+5; % dur 3
    %% SPM ONSETS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% SPM ONSETS - 2 runs per condition - instruction not separate yet
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    onsets{1} = faceons   ;
    % FACEINST can either be included in this, or separately modeled
    onsets{2} = sceneons   ;
    onsets{3} = restons; %[ (localizer.IBI_onsettime(1, :)-PULSEkeytime)/TR  ...
    %(localizer.IBI_onsettime(2, :)-PULSEkeytime)/TR ];
    
    durations{1} = repmat(	5 , 1, length(onsets{1}));
    durations{2} = repmat(	5 , 1, length(onsets{2}));
    durations{3} = repmat(	3 , 1, length(onsets{3}));
    %
    names{1} = 'face';
    names{2} = 'scene';
    names{3} = 'rest';
    
    %% SAVE onset FILE for each run
    spm_ons_file_run = ['SPM_LOC2_shift' num2str(shift_TRs) '_onsets_s' num2str(s) '_allin1run.mat'];
    save(['/usr/people/erhee/thesis/mvpa/onsets/' spm_ons_file_run], 'onsets', 'durations', 'names');
end