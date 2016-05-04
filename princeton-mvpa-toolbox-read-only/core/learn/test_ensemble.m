function [ acts scratchpad ] = test_ensemble(  testpats, testtargs, scratchpad )

    model = scratchpad.model;
    scratchpad.predicted_label = model.predict(testpats');
    
    % ACTS = is an nOuts x nTestTimepoints matrix that contains the activations of the output units at test. 
    % We'll fill acts using winner-take-all activation based on scratchpad.predicted_labels 
    acts = zeros(size(testtargs)); % initilize to all zeros 
    for i = 1:size(acts,1) 
        acts(i,scratchpad.predicted_label==i) = 1; % otherwise it remains zero from initilization 
    end
end

