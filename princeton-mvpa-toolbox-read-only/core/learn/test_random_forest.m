function [ acts scratchpad ] = test_random_forest(  testpats, testtargs, scratchpad )

    rf = scratchpad.model;
    mode = scratchpad.mode;
    rfresults_char = rf.predict(testpats');
    if strcmp(mode,'classification') == 1
        for ind = 1:numel(rfresults_char);
            scratchpad.predicted_label(ind) = str2num(rfresults_char{ind});
        end

        % ACTS = is an nOuts x nTestTimepoints matrix that contains the activations of the output units at test. 
        % We'll fill acts using winner-take-all activation based on scratchpad.predicted_labels 
        acts = zeros(size(testtargs)); % initilize to all zeros 
        for i = 1:size(acts,1) 
            acts(i,scratchpad.predicted_label==i) = 1; % otherwise it remains zero from initilization 
        end
    else
        acts = rf_results_char;
    end
end

