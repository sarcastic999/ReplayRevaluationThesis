function [scratchpad] = train_random_forest(trainpats,traintargs,class_args,cv_args)

    %% process arguments
    % default parameters
    defaults.nTrees = 500;
    defaults.mode = 'classification';
    class_args = mergestructs(class_args, defaults);
    nTrees = class_args.nTrees;
    mode = class_args.mode;
    
    %% call the classifier function
    if strcmp(mode,'classification') == 1
        [train_max_val trainlabs] = max(traintargs);
        B = TreeBagger(nTrees,trainpats', trainlabs, 'Method', mode);
    elseif strcmp(mode,'regression') == 1
        B = TreeBagger(nTrees,trainpats', traintargs, 'Method', mode);
    end

    %% pack the results

    scratchpad.model = B;
    scratchpad.nTrees         = nTrees;
    scratchpad.mode = mode;
end

