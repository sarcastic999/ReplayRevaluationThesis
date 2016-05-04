% This is an auxiliary script to programmatically extract rho and p values
% for correlations

disp('LOC1XREST')
setenv('SGE_LOCALIZER', num2str(1)); % change for localizer
setenv('SGE_DATARANGE', 'REST');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC2XREST')
setenv('SGE_LOCALIZER', num2str(2)); % change for localizer
setenv('SGE_DATARANGE', 'REST');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC12XREST')
setenv('SGE_LOCALIZER', num2str(12)); % change for localizer
setenv('SGE_DATARANGE', 'REST');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC1XALLPHASE2')
setenv('SGE_LOCALIZER', num2str(1)); % change for localizer
setenv('SGE_DATARANGE', 'ALLPHASE2');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC2XALLPHASE2')
setenv('SGE_LOCALIZER', num2str(2)); % change for localizer
setenv('SGE_DATARANGE', 'ALLPHASE2');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC12XALLPHASE2')
setenv('SGE_LOCALIZER', num2str(12)); % change for localizer
setenv('SGE_DATARANGE', 'ALLPHASE2');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC1XPHASE2NOREST')
setenv('SGE_LOCALIZER', num2str(1)); % change for localizer
setenv('SGE_DATARANGE', 'PHASE2NOREST');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC2XPHASE2NOREST')
setenv('SGE_LOCALIZER', num2str(2)); % change for localizer
setenv('SGE_DATARANGE', 'PHASE2NOREST');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;

disp('LOC12XPHASE2NOREST')
setenv('SGE_LOCALIZER', num2str(12)); % change for localizer
setenv('SGE_DATARANGE', 'PHASE2NOREST');
reval_noreval_noise_nonoise_classifier_Rplot
clear all;
