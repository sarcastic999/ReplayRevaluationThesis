%% This file generates onsets MVPA style-- choose which type of inset
%  PULSEkeytime
function [regs rest_regs]= mvpa_phase2_selector_generator(subject, run)
baseDirFSL      =  '/jukebox/norman/reprev/';%      '/Volumes/cohen-2/Ida/IM_replayReval/';
TR                      = 2.08;
shift_TRs      = 3;
%%%%%%%%%% START %%%%%%%%%%%%%
regs=[];
in_dir   = [baseDirFSL  'behavioral/newS' num2str(subject) '/']; %'onsets/' subj{s} '/'];
clear pulse exp params results; % so we don't get interference
in_beh_file = ['run' num2str(run) '.mat'];
load( [ in_dir in_beh_file]);

PULSEkeytime = pulse.PULSEkeytime;

phase2ons = exp.phase{2}.phase_onset-PULSEkeytime;
%phase3ons = exp.phase{3}.phase_onset-PULSEkeytime;
rest_onsets = exp.phase{2}.restOns-PULSEkeytime; 

phase2TRonset = ceil(phase2ons/TR)+shift_TRs;
phase2TRoffset = ceil(max(rest_onsets)/TR)+shift_TRs + 14;

%% IS REST FACE OR SCENE?
city        = exp.cityJuxt(exp.run);
regs.conds = [ 0;0];

if mod(city, 2)==1
    stateOneCat = 2; %scene
else
    stateOneCat = 1; %face
end
stateOneCat
phase2TRs = phase2TRonset:phase2TRoffset;
regs.conds(stateOneCat, phase2TRs ) = 1;

%% treating the entire localizer as 1 run, which it is really!
regs.runs = ones(1, numel( regs.conds(1,:) )  );

%% also include REST regs -- optional, and for testing to ida's rest regs

restOns = exp.phase{2}.restOns - PULSEkeytime;
restTRonset = ceil(restOns/TR) + shift_TRs;
restTRoffset = restTRonset + 14;
for ind = 1:numel(restTRoffset) 
    rest_regs.conds(stateOneCat,restTRonset(ind):restTRoffset(ind)) = 1;
end
rest_regs.runs = ones(1, numel(regs.conds(1,:)));
