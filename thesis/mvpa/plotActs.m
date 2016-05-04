function [masterData, masterIpsiData, masterContraData] = plotActs()
clear all;
NUM_RUNS = 4;
penalty = 5;
classifier = 'L2_RLR';
period_len = 15;
GOOD_REVAL_SUBJECTS_LOC1 = [2, 5, 25, 15]; % top four sort([behavioralMeasure(:,2) + behavioralMeasure(:,4)])
GOOD_REVAL_SUBJECTS_LOC2 = [5, 25, 15];
BAD_REVAL_SUBJECTS_LOC1 = [21 8 19 22]; % bottom four sort([behavioralMeasure(:,2) + behavioralMeasure(:,4)])
BAD_REVAL_SUBJECTS_LOC2 = [21 8 19 22];

RUN2_GOOD_REVAL = [ 1     2     3      11    12    13    15    17     5    14    18    25  23    16];
RUN2_BAD_REVAL = [ 4    20    21     6     7     8     9    19    22    26];

RUN4_GOOD_REVAL =[     2     5     9    25     6     7    15];
RUN4_BAD_REVAL = [20     1     3     4  11    12    13    14    16    17    18    23     26     8    19    21    22];


% intersect(find(behavioralMeasure(:,2) < 0 ), find(behavioralMeasure(:,4)<0))'
GOOD_JOINT_REVAL_BEHAVIOR_CHANGE = [2     5    15    20    25 ] ;
%intersect(find(behavioralMeasure(:,2) >= 0),find(behavioralMeasure(:,4)>=0))'
BAD_JOINT_REVAL_BEHAVIOR_CHANGE =  [8    19    22    26] ;


%localizer=1:2
localizer_set=1;
for localizer = localizer_set
    clear masterData;
    clear categoryDependentFullData;
    clear masterIpsiData;
    clear masterContraData;
    if localizer == 1
        VALID_SUBJECTS = [1:9 11:23 25:26];
        %VALID_SUBJECTS = GOOD_REVAL_SUBJECTS_LOC1;
        %VALID_SUBJECTS = BAD_JOINT_REVAL_BEHAVIOR_CHANGE;
        subplotsize_x = 4;
        subplotsize_y = 6;
    else
        VALID_SUBJECTS = [5:9 11:23 25:26];
        %VALID_SUBJECTS = GOOD_REVAL_SUBJECTS_LOC2;
        subplotsize_x = 4;
        subplotsize_y = 5;
    end
    %% Indidividual Subject Subplots
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    for subject = VALID_SUBJECTS
        clear results;
        clear meanRunMdp;
        classifier_param_string = sprintf('train_%s_test_%s_penalty_%d',classifier,classifier,penalty);
        mvpa_filepath = sprintf('/usr/people/erhee/thesis/mvpa/MVPA_Rest_Face_Scene/Loc%dXRest_subject%d_%s.mat',localizer, subject,classifier_param_string);
        load(mvpa_filepath);
        mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
        conditions_filename = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
        load(conditions_filename);
        mdp_conditions_order = meanRunMdp(1,:);
        for run = 1:NUM_RUNS
            startIndex = (run-1)*period_len*3 + 1; % 3 periods of 15 TRs each
            endIndex = startIndex + period_len*3 - 1;
            mdpStartIndex = (mdp_conditions_order(run)-1)*(period_len*3) + 1;
            mdpEndIndex = mdpStartIndex + (period_len*3) - 1;
            faceActs = results{1}.iterations(2).acts(1,startIndex:endIndex);
            sceneActs = results{2}.iterations(2).acts(2,startIndex:endIndex);
            subplot(subplotsize_x,subplotsize_y,find(VALID_SUBJECTS==subject));
            plot(mdpStartIndex:mdpEndIndex,[ faceActs ; sceneActs ]);
            hold on;
            aggregateData = faceActs.*sceneActs;
            averageFaceEvidence = mean(faceActs);
            averageSceneEvidence = mean(sceneActs);
            %aggregateData = mean([faceActs;sceneActs]);
            plot(mdpStartIndex:mdpEndIndex,aggregateData, 'Color','red');
            average = mean(aggregateData);
            line([mdpStartIndex mdpEndIndex], [average average], 'LineWidth',4,'Color','red');
            line([mdpStartIndex mdpEndIndex], [averageFaceEvidence averageFaceEvidence], 'LineWidth',4,'Color','blue');
            line([mdpStartIndex mdpEndIndex], [averageSceneEvidence averageSceneEvidence], 'LineWidth',4,'Color','green');
            line([mdpStartIndex mdpStartIndex], [0 1], 'LineWidth',4,'Color','black');
            masterData(mdpStartIndex:mdpEndIndex, find(VALID_SUBJECTS==subject)) = aggregateData;
        end
        hold off;
    end
    suptitle(sprintf('Localizer %d Subject-Level MVPA Analysis', localizer));
    
    %% Indidividual Subject Subplots - S2 category dependent. Presenting VS Counterpart Evidence.
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    for subject = VALID_SUBJECTS
        clear results;
        clear meanRunMdp;
        classifier_param_string = sprintf('train_%s_test_%s_penalty_%d',classifier,classifier,penalty);
        mvpa_filepath = sprintf('/usr/people/erhee/thesis/mvpa/MVPA_Rest_Face_Scene/Loc%dXRest_subject%d_%s.mat',localizer, subject,classifier_param_string);
        load(mvpa_filepath);
        mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
        conditions_filename = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
        load(conditions_filename);
        mdp_conditions_order = meanRunMdp(1,:);
        mdp_S1 = meanRunMdp(3,:);
        for run = 1:NUM_RUNS
            startIndex = (run-1)*period_len*3 + 1; % 3 periods of 15 TRs each
            endIndex = startIndex + period_len*3 - 1;
            mdpStartIndex = (mdp_conditions_order(run)-1)*(period_len*3) + 1;
            mdpEndIndex = mdpStartIndex + (period_len*3) - 1;
            faceActs = results{1}.iterations(2).acts(1,startIndex:endIndex);
            sceneActs = results{2}.iterations(2).acts(2,startIndex:endIndex);
            if (mdp_S1(run) == 1) % face
                ipsilateralActs = sceneActs;
                contralateralActs = faceActs;
            elseif(mdp_S1(run) == 2) % scene
                ipsilateralActs = faceActs;
                contralateralActs = sceneActs;
            end
            subplot(subplotsize_x,subplotsize_y,find(VALID_SUBJECTS==subject));
            plot(mdpStartIndex:mdpEndIndex,[ ipsilateralActs ], 'k', mdpStartIndex:mdpEndIndex, contralateralActs,'m');
            hold on;
          %  aggregateData = ipsilateralActs.*contralateralActs;
            averageIpsilateralEvidence = mean(ipsilateralActs);
            averageContralateralEvidence = mean(contralateralActs);
            %aggregateData = mean([faceActs;sceneActs]);
          %  plot(mdpStartIndex:mdpEndIndex,aggregateData, 'Color','red');
          %  average = mean(aggregateData);
          %  line([mdpStartIndex mdpEndIndex], [average average], 'LineWidth',4,'Color','red');
            line([mdpStartIndex mdpEndIndex], [averageIpsilateralEvidence averageIpsilateralEvidence], 'LineWidth',4,'Color','k');
            line([mdpStartIndex mdpEndIndex], [averageContralateralEvidence averageContralateralEvidence], 'LineWidth',4,'Color','m');
            line([mdpStartIndex mdpStartIndex], [0 1], 'LineWidth',4,'Color','black');
            masterIpsiData(mdpStartIndex:mdpEndIndex, find(VALID_SUBJECTS==subject)) = ipsilateralActs;
            masterContraData(mdpStartIndex:mdpEndIndex, find(VALID_SUBJECTS==subject)) = contralateralActs;
        end
        hold off;
    end
    suptitle(sprintf('Localizer %d Subject-Level S1 VS S2 MVPA Analysis', localizer));
    
    %% Group Level Category-Dependent Average for each localizer.
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    for run = 1:NUM_RUNS
        startIndex = (run-1)*45 + 1;
        endIndex = startIndex + 44;
        ipsilateralAverageActs = mean(masterIpsiData,2);
        contralateralAverageActs = mean(masterContraData,2);
        plot(startIndex:endIndex, ipsilateralAverageActs(startIndex:endIndex),'k', startIndex:endIndex, contralateralAverageActs(startIndex:endIndex),'m');
        hold on;
        ipsiAverage = mean(ipsilateralAverageActs(startIndex:endIndex));
        contraAverage = mean(contralateralAverageActs(startIndex:endIndex));
        line([startIndex endIndex], [ipsiAverage ipsiAverage], 'LineWidth',4,'Color','k');
        line([startIndex endIndex], [contraAverage contraAverage], 'LineWidth',4,'Color','m');

        for period = 1:3
            periodStartIndex = startIndex+(period-1)*15;
            periodEndIndex = periodStartIndex + 14;
            line([periodEndIndex, periodEndIndex], [0 1], 'LineWidth',1,'Color','black','LineStyle','--');
            ipsiPeriodAverage = mean(ipsilateralAverageActs(periodStartIndex:periodEndIndex));
            contraPeriodAverage = mean(contralateralAverageActs(periodStartIndex:periodEndIndex));
            line([periodStartIndex periodEndIndex], [ipsiPeriodAverage ipsiPeriodAverage], 'LineWidth',2,'Color','k','LineStyle','--');
            line([periodStartIndex periodEndIndex], [contraPeriodAverage contraPeriodAverage], 'LineWidth',2,'Color','m','LineStyle','--');
        end

        line([startIndex startIndex], [0 1], 'LineWidth',4,'Color','black');
    end
    title(sprintf('Localizer %d S2 VS S1 Group-Level FFAXPPA Average', localizer));
    xlabelSpace = '                                                                       ';
    xlabel({sprintf('No Noise No Reval%sNo Noise Reval%sNoise No Reval%sNoise Reval',xlabelSpace,xlabelSpace,xlabelSpace);'Rest Period TRs'});
    ylabel('Average Evidence');
    legend('Stage 2 Category Evidence', 'Stage 1 Category Evidence','Stage 2 run rest group average evidence', 'Stage 1 run rest group average evidence', 'Stage 2 minirest group average evidence', 'Stage 1 minirest group average evidence');
%    legend('S2 evidence', 'S1 evidence');
    
    %% Group Level Category-Dependent Average for each localizer (First 3TR and Last 1TR removed for each minirest period)
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    startTruncateTRs = 3;
    endTruncateTRs = 1;
    for run = 1:NUM_RUNS
        startIndex = (run-1)*45 + 1;
        endIndex = startIndex + 44;
        ipsilateralAverageActs = mean(masterIpsiData,2);
        contralateralAverageActs = mean(masterContraData,2);
        hold on;

        ipsiSum = 0;
        contraSum = 0;
        for period = 1:3
            periodStartIndex = startIndex+(period-1)*15 + startTruncateTRs;
            periodEndIndex = periodStartIndex + 14 - endTruncateTRs - startTruncateTRs;
            plot(periodStartIndex:periodEndIndex, ipsilateralAverageActs(periodStartIndex:periodEndIndex),'k');
            plot(periodStartIndex:periodEndIndex, contralateralAverageActs(periodStartIndex:periodEndIndex),'m');
            ipsiPeriodAverage = mean(ipsilateralAverageActs(periodStartIndex:periodEndIndex));
            ipsiSum = ipsiSum + sum(ipsilateralAverageActs(periodStartIndex:periodEndIndex));
            contraPeriodAverage = mean(contralateralAverageActs(periodStartIndex:periodEndIndex));
            contraSum = contraSum + sum(contralateralAverageActs(periodStartIndex:periodEndIndex));
            line([periodEndIndex + endTruncateTRs, periodEndIndex + endTruncateTRs], [0 1], 'LineWidth',1,'Color','black','LineStyle','--');
            line([periodStartIndex periodEndIndex], [ipsiPeriodAverage ipsiPeriodAverage], 'LineWidth',2,'Color','k','LineStyle','--');
            line([periodStartIndex periodEndIndex], [contraPeriodAverage contraPeriodAverage], 'LineWidth',2,'Color','m','LineStyle','--');
        end

        ipsiAverage = ipsiSum/((15 - startTruncateTRs - endTruncateTRs)*3);
        contraAverage = contraSum/((15 - startTruncateTRs - endTruncateTRs)*3);
        line([startIndex endIndex], [ipsiAverage ipsiAverage], 'LineWidth',4,'Color','k');
        line([startIndex endIndex], [contraAverage contraAverage], 'LineWidth',4,'Color','m');

        line([startIndex startIndex], [0 1], 'LineWidth',4,'Color','black');
    end
    title(sprintf('Localizer %d S2 VS S1 (First3TR, Last1TR removed) Group-Level FFAXPPA Average', localizer));
    xlabelSpace = '                                                                       ';
    xlabel({sprintf('No Noise No Reval%sNo Noise Reval%sNoise No Reval%sNoise Reval',xlabelSpace,xlabelSpace,xlabelSpace);'Rest Period TRs'});
    ylabel('Average Evidence');
    legend('S2 evidence', 'S1 evidence');
    
    %% All subjects overlaid on top
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    for subject = VALID_SUBJECTS
        clear results;
        clear meanRunMdp;
        classifier_param_string = sprintf('train_%s_test_%s_penalty_%d',classifier,classifier,penalty);
        mvpa_filepath = sprintf('/usr/people/erhee/thesis/mvpa/MVPA_Rest_Face_Scene/Loc%dXRest_subject%d_%s.mat',localizer, subject,classifier_param_string);
        load(mvpa_filepath);
        mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
        conditions_filename = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
        load(conditions_filename);
        mdp_conditions_order = meanRunMdp(1,:);
        for run = 1:NUM_RUNS
            startIndex = (run-1)*45 + 1;
            endIndex = startIndex + 44;
            mdpStartIndex = (mdp_conditions_order(run)-1)*45 + 1;
            mdpEndIndex = mdpStartIndex + 44;
            faceActs = results{1}.iterations(2).acts(1,startIndex:endIndex);
            sceneActs = results{2}.iterations(2).acts(2,startIndex:endIndex);
            plot(mdpStartIndex:mdpEndIndex,[ faceActs ; sceneActs ]);
            hold on;
            aggregateData = faceActs.*sceneActs;
            %aggregateData = mean([faceActs;sceneActs]);
            plot(mdpStartIndex:mdpEndIndex,aggregateData, 'Color','red');
            average = mean(aggregateData);
            line([mdpStartIndex mdpEndIndex], [average average], 'LineWidth',4,'Color','red');

            line([mdpStartIndex mdpStartIndex], [0 1], 'LineWidth',4,'Color','black');
            masterData(mdpStartIndex:mdpEndIndex, find(VALID_SUBJECTS==subject)) = aggregateData;
        end
    end
    title(sprintf('Localizer %d Subject-Level Analysis Overlaid', localizer));
    xlabelSpace = '                                                                       ';
    xlabel({sprintf('No Noise No Reval%sNo Noise Reval%sNoise No Reval%sNoise Reval',xlabelSpace,xlabelSpace,xlabelSpace);'Rest Period TRs'});
    ylabel('Average FaceXScene Evidence');
    %% Group Level Average for each localizer.
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    masterDataAverage(:,localizer) = mean(masterData,2);
    for run = 1:NUM_RUNS
        startIndex = (run-1)*45 + 1;
        endIndex = startIndex + 44;
        averageActs = masterDataAverage(startIndex:endIndex,localizer);
        plot(startIndex:endIndex,averageActs, 'Color','red');
        hold on;
        average = mean(averageActs);
        line([startIndex endIndex], [average average], 'LineWidth',4,'Color','red');

        for period = 1:3
            periodStartIndex = startIndex+(period-1)*15;
            periodEndIndex = periodStartIndex + 14;
            line([periodEndIndex, periodEndIndex], [0 1], 'LineWidth',1,'Color','black','LineStyle','--');
            periodAverage = mean(masterDataAverage(periodStartIndex:periodEndIndex,localizer));
            line([periodStartIndex periodEndIndex], [periodAverage periodAverage], 'LineWidth',2,'Color','red','LineStyle','--');
        end

        line([startIndex startIndex], [0 1], 'LineWidth',4,'Color','black');
    end
    title(sprintf('Localizer %d Group-Level FFAXPPA Average', localizer));
    xlabelSpace = '                                                                       ';
    xlabel({sprintf('No Noise No Reval%sNo Noise Reval%sNoise No Reval%sNoise Reval',xlabelSpace,xlabelSpace,xlabelSpace);'Rest Period TRs'});
    ylabel('Average FaceXScene Evidence');
    
    %% Group Level Average without last TR of each rest period for each localizer.
    FigHandle = figure('Position', [100, 100, 2000, 895]);
    masterDataTruncated = masterData;
    masterDataTruncated([1:12]*15,:) = []; % remove every 15 element
    masterDataTruncatedAverage(:,localizer) = mean(masterDataTruncated,2);
    for run = 1:NUM_RUNS
        startIndex = (run-1)*(45-3) + 1;
        endIndex = startIndex + (44-3);
        averageActs = masterDataTruncatedAverage(startIndex:endIndex,localizer);
        plot(startIndex:endIndex,averageActs, 'Color','red');
        hold on;
        average = mean(averageActs);
        line([startIndex endIndex], [average average], 'LineWidth',4,'Color','red');

        for period = 1:3
            periodStartIndex = startIndex+(period-1)*14;
            periodEndIndex = periodStartIndex + 13;
            line([periodEndIndex, periodEndIndex], [0 1], 'LineWidth',1,'Color','black','LineStyle','--');
            periodAverage = mean(masterDataTruncatedAverage(periodStartIndex:periodEndIndex,localizer));
            line([periodStartIndex periodEndIndex], [periodAverage periodAverage], 'LineWidth',2,'Color','red','LineStyle','--');
        end

        line([startIndex startIndex], [0 1], 'LineWidth',4,'Color','black');
    end
    title(sprintf('Localizer %d Group-Level FFAXPPA Average Truncated 1 TR from end of each period', localizer));
    xlabelSpace = '                                                                       ';
    xlabel({sprintf('No Noise No Reval%sNo Noise Reval%sNoise No Reval%sNoise Reval',xlabelSpace,xlabelSpace,xlabelSpace);'Rest Period TRs'});
    ylabel('Average FaceXScene Evidence');
end

%% Group Level Average for both Localizers, overlaid.
FigHandle = figure('Position', [100, 100, 2000, 895]);
h = zeros(1,6);
graphColors = ['r','b'];
for localizer = localizer_set
    for run = 1:NUM_RUNS
        startIndex = (run-1)*45 + 1;
        endIndex = startIndex + 44;
        averageActs = masterDataAverage(startIndex:endIndex,localizer);
        h(localizer) = plot(startIndex:endIndex,averageActs, 'Color',graphColors(localizer));
        hold on;
        average = mean(averageActs);
        h(2+localizer) = line([startIndex endIndex], [average average], 'LineWidth',4,'Color',graphColors(localizer));

        for period = 1:3
            periodStartIndex = startIndex+(period-1)*15;
            periodEndIndex = periodStartIndex + 14;
            line([periodEndIndex, periodEndIndex], [0 1], 'LineWidth',1,'Color','black','LineStyle','--');
            periodAverage = mean(masterDataAverage(periodStartIndex:periodEndIndex,localizer));
            h(4+localizer) = line([periodStartIndex periodEndIndex], [periodAverage periodAverage], 'LineWidth',2,'Color',graphColors(localizer),'LineStyle','--');
        end

        line([startIndex startIndex], [0 1], 'LineWidth',4,'Color','black');
    end
end
legend(h,'Localizer 1', 'Localizer 2','Localizer 1 Global Group Average', 'Localizer 2 Global Group Average', 'Localizer 1 Local Group Average', 'Localizer 2 Local Group Average');
xlabelSpace = '                                                                       ';
xlabel({sprintf('No Noise No Reval%sNo Noise Reval%sNoise No Reval%sNoise Reval',xlabelSpace,xlabelSpace,xlabelSpace);'Rest Period TRs'});
ylabel('Average FaceXScene Evidence');
title(sprintf('Rest Period MVPA (%s) Group Level Timeseries Analysis',regexprep(classifier_param_string,'_',' ')));
end