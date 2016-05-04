% This script takes subject behavioral data and plots it against fmri data
% and runs correlation analysis to see if we can predict the behavior from
% fmri data.

%% Load Preset Classifiers
load_classifiers;

%% Tweakable Parameters
if isempty(getenv('SGE_CLASSIFIER_ID'))
    classifier_index = 1;
else
    classifier_index = str2num(  getenv('SGE_CLASSIFIER_ID')  );
end
class_args = classifiers{classifier_index};
if isempty(getenv('SGE_MVPA_ONLY'))
    mvpa_only = 0;
else
    mvpa_only = str2num(getenv('SGE_MVPA_ONLY'));
end
if isempty(getenv('SGE_AGG'))
    aggregation_method = 'dot_product';
else
    aggregation_method = getenv('SGE_AGG');
end

if isempty(getenv('SGE_ROI'))
    roi = 'FFA_PPA';
else
    roi = getenv('SGE_ROI');
end

if isempty(getenv('SGE_LOCALIZER'))
    localizer = '1';
else
    localizer = getenv('SGE_LOCALIZER');
end

if isempty(getenv('SGE_DATARANGE'))
    datarange = 'REST';
else
    datarange = getenv('SGE_DATARANGE');
end

if isempty(getenv('SGE_DATA_PRUNING'))
    datapruning = '';
else
    datapruning = getenv('SGE_DATA_PRUNING');
end

if isempty(getenv('SGE_TASK_ID'))
    tid = '0';
else
    tid = getenv('SGE_TASK_ID');
end

if isempty(getenv('SGE_GRAPH_ID'))
    gid = '';
else
    gid = getenv('SGE_GRAPH_ID');
end
%% environment setup
environment_setup;

%% Experiment Parameters
NUM_RUNS = 4;
if str2num(localizer) == 1
    VALID_SUBJECTS = [1:9 11:23 25:26];
else
    VALID_SUBJECTS = [5:9 11:23 25:26];
end
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
        
    fMRIMeasure= zeros(size(behavioralMeasure));
       
if mvpa_only % don't do anything other than running mvpa
   for subj = VALID_SUBJECTS
       switch (datarange)
            case 'REST'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
            case 'MINIREST1'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
            case 'MINIREST2'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
            case 'MINIREST3'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
            case 'ALLPHASE2'
                [acts, mdp_order, s1cat] = getActs(subj, class_args, roi, localizer, 'ALLPHASE2');
            case 'PHASE2NOREST'
                [acts, mdp_order, s1cat] = getActs(subj, class_args, roi, localizer, 'PHASE2NOREST');
       end
   end
else
    for subj = VALID_SUBJECTS
        clear acts mdp_order s1cat len delInds;
       switch (datarange)
            case 'REST'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
                xlab_text = 'PHASE2 REST';
            case 'MINIREST1'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
                selector = [1:15, 46:60, 91:105, 136:150];
                acts.face = acts.face(selector);
                acts.scene = acts.scene(selector);
                acts.run_lengths = acts.run_lengths - 30;
                xlab_text = 'PHASE2 MINIREST1';
            case 'MINIREST2'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
                selector = [16:30, 61:75, 106:120, 151:165];
                acts.face = acts.face(selector);
                acts.scene = acts.scene(selector);
                acts.run_lengths = acts.run_lengths - 30;
                xlab_text = 'PHASE2 MINIREST2';
            case 'MINIREST3'
                [acts, mdp_order, s1cat]= getActs(subj, class_args, roi, localizer, 'Rest');
                selector = [31:45, 76:90, 121:135, 166:180];
                acts.face = acts.face(selector);
                acts.scene = acts.scene(selector);
                acts.run_lengths = acts.run_lengths - 30;
                xlab_text = 'PHASE2 MINIREST3';
            case 'ALLPHASE2'
                [acts, mdp_order, s1cat] = getActs(subj, class_args, roi, localizer, 'ALLPHASE2');
                xlab_text = 'ALLPHASE2';
                datapruning = ''; % don't prune unless rest
            case 'PHASE2NOREST'
                [acts, mdp_order, s1cat] = getActs(subj, class_args, roi, localizer, 'PHASE2NOREST');
                xlab_text = 'PHASE2 NO REST';
                datapruning = ''; % don't prune unless rest
       end

        switch(datapruning)
           case 'REST_TRUNCATE_1'
               delInds = 15:15:length(acts.face);
               acts.face(delInds) = [];
               acts.scene(delInds) = [];
               acts.run_lengths = acts.run_lengths - (numel(delInds)/4);
           case 'REST_TRIM_5'
               len = length(acts.face);
               delInds = [1:15:len, 2:15:len, 3:15:len, 4:15:len, 5:15:len];
               acts.face(delInds) = [];
               acts.scene(delInds) = [];
               acts.run_lengths = acts.run_lengths - (numel(delInds)/4);
           case 'REST_TRIM_AND_TRUNCATE'
               len = length(acts.face);
               delInds = [1:15:len, 2:15:len, 3:15:len, 4:15:len, 5:15:len 15:15:len];
               acts.face(delInds) = [];
               acts.scene(delInds) = [];
               acts.run_lengths = acts.run_lengths - (numel(delInds)/4);
        end
        %% Aggregation
        q = mask_aggregation(acts, aggregation_method, s1cat);
        xlab_text = sprintf('%s %s',xlab_text, regexprep(aggregation_method,'_',' '));
        %% copy subject data to higher level dataset
        fMRIMeasure(subj,:) = q;
    end

    validFMRIMeasure = fMRIMeasure(VALID_SUBJECTS,:);
    validBehavioralMeasure = behavioralMeasure(VALID_SUBJECTS,:);

    %% Plot
    if (produce_graphs)
        jsonrep = savejson('',class_args);
        comma_indices = find(jsonrep == ',');
        if numel(comma_indices) >1
            custom_param_begin_index = comma_indices(2)+1;
            unprocessed_params = jsonrep(custom_param_begin_index:end);
            processed_params = regexprep(regexprep(unprocessed_params,'\n|\t|}|\"',''),': ','_');
        else
            processed_params = '';
        end

        dirname = sprintf('%s_%s_%s_%s_%s_%s', getenv('SGE_LOCALIZER'), getenv('SGE_ROI'), getenv('LOC2TRSHIFT'), getenv('LOC2TR'), getenv('SGE_DATARANGE'), getenv('SGE_DATA_PRUNING'));
        outDir = sprintf('/usr/people/erhee/thesis/mvpa/figures');
        if ~exist(outDir)
            mkdir(outDir);
        end;
        filename = sprintf('%s_%s_%s_%s',class_args.train_funct_name, class_args.test_funct_name, processed_params, aggregation_method);
        error_plot(validFMRIMeasure , xlab_text);
        saveFigure(sprintf('%s/[%s]_[%s]_%s_Err.fig',outDir,tid, gid, filename));
        close(gcf);
        plot_scatters_all(validFMRIMeasure, validBehavioralMeasure, xlab_text);
        saveFigure(sprintf('%s/[%s]_[%s]_%s_All.fig',outDir, tid, gid, filename));
        close(gcf);
        plot_scatters_collapse(validFMRIMeasure, validBehavioralMeasure, xlab_text);
        saveFigure(sprintf('%s/[%s]_[%s]_%s_R.fig',outDir, tid, gid, filename));
        close(gcf);
        plot_scatters_collapse_noise(validFMRIMeasure, validBehavioralMeasure, xlab_text);
        saveFigure(sprintf('%s/[%s]_[%s]_%s_N.fig',outDir, tid, gid, filename));
        close(gcf);
    end
end
