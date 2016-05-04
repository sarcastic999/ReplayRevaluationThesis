function [ regs ] = loc2_createRegressor(subject)
environment_setup;
if(~isempty(getenv('LOC2TRSHIFT')))
    shiftTRs = str2num(getenv('LOC2TRSHIFT'));
else
    shiftTRs = 3;
end
% Delete Last TR? -- see mvpa_Loc1XLoc2_3set_predction_accuracies.m for motivation into why 3rd TR is not good.
if(~isempty(getenv('LOC2TR')))
   num_TRs = str2num(getenv('LOC2TR')); % use first x TRs only
else
    num_TRs = 3;
end

%% Load Localizer Pattern
lsdir = dir(sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/*.feat',subject));
feat_dir = lsdir(1).name;
raw_volume_filename = sprintf('/jukebox/norman/reprev/subj/newS%d/NII/prestat_loc2/%s/filtered_func_data.nii',subject,feat_dir);

if exist(raw_volume_filename)==0
    zippedfile = sprintf('%s.gz', raw_volume_filename);
    gunzip(zippedfile);
end
localizerVolume    = spm_read_hdr(raw_volume_filename);
localizerLength = localizerVolume.dime.dim(5); %% Total Length of localizer

%% Load Localizer Conditions
conditions_filename = sprintf('/usr/people/erhee/thesis/mvpa/onsets/SPM_LOC2_shift%d_onsets_s%d_allin1run.mat',shiftTRs,subject);
load(conditions_filename);
% Now, we should have durations, onsets, and names in our workbench.
if numel(onsets{1}) > localizerLength
    onsets{1} = onsets{1}(:,1:localizerLength); % in case reg was longer than volume
    onsets{2} = onsets{2}(:,1:localizerLength); % in case reg was longer than volume
end
regs.conds(1,:) = zeros(1, localizerLength);
regs.conds(2,:) = zeros(1, localizerLength);
regs.runs = ones(1, localizerLength);
%% faces, using only first three TRs -- note:Last TR appears to be problematic?
for i = 1:numel(onsets{1})
    regs.conds(1, onsets{1}(i):onsets{1}(i) + num_TRs - 1) = 1;
end
%% faces, using only first three TRs -- note:Last TR appears to be problematic?
for i = 1:numel(onsets{2})
    regs.conds(2, onsets{2}(i):onsets{2}(i) + num_TRs - 1) = 1;
end

