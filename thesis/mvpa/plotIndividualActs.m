function plotIndividualActs(subject)

NUM_RUNS = 4;
penalty = 5;
classifier = 'L2_RLR';
period_len = 15;
behavioralMeasure = [
    0.2	-1.0	1.0	0
    0.2	-1.0	0.0	-1.0
    0.2	-1.0	0	0.0
    0.0	-0.466666666667	0	0.0
    0	-0.8	0.0	-1.0
    0.0	0	1.0	-0.8
    0.0666666666667	0	0.0	-0.55
    0	0	0.3	0.0666666666667
    -1.0	0	0	-1.0
    0.2	-1.0	-0.8	0
    0.2	-1.0	-0.333333333333	0
    0.2	-1.0	0.4	0
    0.2	-1.0	-0.75	0
    0.2	-0.8	-0.8	0
    0.0	-1.0	0.0	-0.55
    0.2	-0.666666666667	0.0	0
    0.4	-1.0	-0.8	0
    0.2	-0.8	0.0	0
    0.4	0	0.0	0.0666666666667
    0.4	-0.1	0.4	-0.1
    0.466666666667	-0.05	0.666666666667	0.1
    0.0	0	-0.25	0.2
    -0.1	-0.75	0.0	0
    -0.25	0.0	0.0	0.2
    -0.25	-0.8	0.0	-1.0
    0.0	0.0	0.0	0
    ];
for localizer=1
    if localizer == 2 && subject <5
        return;
    end
    %% Indidividual Subject Rest Plots
    FigHandle = figure('Position', [100, 100, 2000, 895]);
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
            plot(mdpStartIndex:mdpEndIndex,[ faceActs ; sceneActs ]);
            hold on;
            %aggregateData = faceActs.*sceneActs;
            aggregateData = mean([faceActs;sceneActs]);
            %plot(mdpStartIndex:mdpEndIndex,aggregateData, 'Color','red');
            average = mean(aggregateData);
            line([mdpStartIndex mdpEndIndex], [0.5 0.5], 'LineWidth',1,'Color','black');
            line([mdpStartIndex mdpEndIndex], [average average], 'LineWidth',3,'Color','red');
            line([mdpStartIndex mdpStartIndex], [0 1], 'LineWidth',4,'Color','black');
        end
        hold off;
    title(sprintf('Localizer %d Subject%d MVPA Rest Analysis:[ %f\t%f\t%f\t%f ]', localizer,subject, behavioralMeasure(subject,1), behavioralMeasure(subject,2), behavioralMeasure(subject,3), behavioralMeasure(subject,4)));
    %% Indidividual Subject No Rest Plots
    FigHandle = figure('Position', [100, 100, 2000, 895]);
        clear results;
        clear meanRunMdp;
        classifier_param_string = sprintf('train_%s_test_%s_penalty_%d',classifier,classifier,penalty);
        mvpa_filepath = sprintf('/usr/people/erhee/thesis/mvpa/MVPA_PHASE2NOREST_Face_Scene/Loc%dXPHASE2NOREST_subject%d_%s.mat',localizer, subject,classifier_param_string);
        load(mvpa_filepath);
        mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
        conditions_filename = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
        load(conditions_filename);
        mdp_conditions_order = meanRunMdp(1,:);
        mdp_conditions_order
        [sum(sum(imregs{1}.conds)) sum(sum(imregs{2}.conds)) sum(sum(imregs{3}.conds)) sum(sum(imregs{4}.conds))]
        endIndex = 0;
        for run = 1:NUM_RUNS
            numTRs = sum(sum(imregs{run}.conds,2));
            expOrderTRs(run) = numTRs;
        end
        for run = 1:NUM_RUNS
            mdpIndex = mdp_conditions_order(run);
            mdpOrderTRs(mdpIndex) = expOrderTRs(run);
        end
        mdpIndices = cumsum(mdpOrderTRs);
        for run = 1:NUM_RUNS
            startIndex = endIndex + 1; % 3 periods of 15 TRs each
            numTRs = sum(sum(imregs{run}.conds,2));
            endIndex = startIndex + numTRs - 1;
            mdpIndex = mdp_conditions_order(run);
            s1Order(mdpIndex) = num2str(find(sum(imregs{run}.conds,2)>0));
            if(mdpIndex == 1)
                mdpStartIndex = 1;
            else
                mdpStartIndex = mdpIndices(mdpIndex -1) + 1;
            end
            mdpEndIndex = mdpIndices(mdpIndex);
            faceActs = results{1}.iterations(2).acts(1,startIndex:endIndex);
            sceneActs = results{2}.iterations(2).acts(2,startIndex:endIndex);
            plot(mdpStartIndex:mdpEndIndex,[ faceActs ; sceneActs ]);
            hold on;
            %aggregateData = faceActs.*sceneActs;
            aggregateData = mean([faceActs;sceneActs]);
            %plot(mdpStartIndex:mdpEndIndex,aggregateData, 'Color','red');
            average = mean(aggregateData);
            line([mdpStartIndex mdpEndIndex], [0.5 0.5], 'LineWidth',1,'Color','black');
            line([mdpStartIndex mdpEndIndex], [average average], 'LineWidth',3,'Color','red');
            line([mdpStartIndex mdpStartIndex], [0 1], 'LineWidth',4,'Color','black');
        end
        hold off;
title(sprintf('Localizer %d Subject%d MVPA No Rest Analysis:[ %f\t%f\t%f\t%f ] & State One Category Order=%s', localizer,subject, behavioralMeasure(subject,1), behavioralMeasure(subject,2), behavioralMeasure(subject,3), behavioralMeasure(subject,4),s1Order));
legend('Face','Scene');
end