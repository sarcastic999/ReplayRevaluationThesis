if ~exist('aggregators_loaded')
    aggregators_loaded = 1;

    %% Preset Aggregation Methods - make sure to modify mask_aggregation.m to reflect changes as well
    aggregation_methods{1} = 'dot_product';
    aggregation_methods{2} = 'mean_product';
    aggregation_methods{3} = 'weighted_dot_product';
    aggregation_methods{4} = 'weighted_average';
    aggregation_methods{5} = 'average_S1_evidence';
    aggregation_methods{6} = 'average_S2_evidence';
    aggregation_methods{7} = 'weighted_S2_evidence';
    aggregation_methods{8} = 'weighted_S1_evidence';
    
    aggregation_methods{9} = 'dot_product_rest_period_1';
    aggregation_methods{10} = 'dot_product_rest_period_2';
    aggregation_methods{11} = 'dot_product_rest_period_3';
    aggregation_methods{12} = 'dot_product_discard_5';
    aggregation_methods{13} = 'dot_FS_custom';
    aggregation_methods{14} = 'dot_FS_custom_rest_period_1_2';
    aggregation_methods{15} = 'dot_product_rest_period_1_2';
    aggregation_methods{16} = 'boosted_dot_product';
    aggregation_methods{17} = 'experimental 1';
    aggregation_methods{18} = 'experimental 2';
    aggregation_methods{19} = 'experimental 3';

end