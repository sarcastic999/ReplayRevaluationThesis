function [ regs ] = createRegressor(subject)
environment_setup;

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
%conditions_filename = sprintf('/jukebox/norman/reprev/behavioral/newS%d/onsets/SPM_LOC2_onsets_s%d_allin1run.mat',subject,subject);
conditions_filename = sprintf('/usr/people/erhee/thesis/mvpa/onsets/SPM_LOC2_shift2_onsets_s%d_allin1run.mat',subject);
load(conditions_filename);
% Now, we should have durations, onsets, and names in our workbench.
if numel(onsets{1}) > localizerLength
    onsets{1} = onsets{1}(:,1:localizerLength); % in case reg was longer than volume
    onsets{2} = onsets{2}(:,1:localizerLength); % in case reg was longer than volume
end
regs.conds(1,:) = zeros(1, localizerLength);
regs.conds(2,:) = zeros(1, localizerLength);
regs.runs = zeros(1, localizerLength);
%% faces, using only first three TRs
for i = 1:numel(onsets{1})
    regs.conds(1, onsets{1}(i):onsets{1}(i) + 2) = 1;
    regs.runs(onsets{1}(i):onsets{1}(i) + 2) = i;
end
%% scenes, using only first three TRs
for i = 1:numel(onsets{2})
    regs.conds(2, onsets{2}(i):onsets{2}(i) + 2) = 1;
    regs.runs(onsets{2}(i):onsets{2}(i) + 2) = i;
end
regs.runs(find(regs.runs==0)) = max(regs.runs)+1; % if we don't do this the code complains


