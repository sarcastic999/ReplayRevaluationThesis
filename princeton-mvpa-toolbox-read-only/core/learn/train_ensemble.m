function [scratchpad] = train_ensemble(trainpats,traintargs,class_args,cv_args)

    %% process arguments
    % default parameters
    defaults.nLearners = 500;
    defaults.learnRate = 0.1;
    defaults.learner = 'Tree';
    defaults.method = 'AdaBoostM1';
    class_args = mergestructs(class_args, defaults);
    nLearners = class_args.nLearners;
    learnRate = class_args.learnRate;
    learnerType = class_args.learner;
    method = class_args.method;
    
    [train_max_val trainlabs] = max(traintargs);
    %% call the classifier function
    if ismember(method,{'AdaBoostM1' 'AdaBoostM2' 'AdaBoostMH' ...
                    'LogitBoost' 'GentleBoost' 'LSBoost' 'RUSBoost' ...
                    'PartitionedEnsemble'})
        model = fitensemble(trainpats',trainlabs,method,nLearners,learnerType,'LearnRate',learnRate);
    else
        model = fitensemble(trainpats',trainlabs,method,nLearners,learnerType);
    end

    %% pack the results

    scratchpad.model = model;
    scratchpad.nLearners         = nLearners;
    scratchpad.learnRate = learnRate;
    scratchpad.learner = learnerType;
    scratchpad.method = method;
end

