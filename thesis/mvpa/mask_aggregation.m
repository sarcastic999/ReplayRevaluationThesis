function [ prod ] = mask_aggregation( acts , method, s1cats)

endIndex = 0;

for run = 1:4
    beginIndex = endIndex + 1;
    endIndex = beginIndex + acts.run_lengths(run) - 1;
    
    faceRun = acts.face(beginIndex:endIndex);
    sceneRun = acts.scene(beginIndex:endIndex);
    
    % face = 1 scene = 2
    s1cat = s1cats(run);

    switch (method)
        case 'dot_product'
            prod(run) = dot(faceRun,sceneRun);
        case 'mean_product'
            prod(run) = mean(faceRun)*mean(sceneRun);
        case 'dot_product_rest_period_1'
            %indices ONLY valid for rest-period data
            prod(run) = dot(faceRun(1:15),sceneRun(1:15));
        case 'dot_product_rest_period_2'
            %indices ONLY valid for rest-period data
            prod(run) = dot(faceRun(16:30),sceneRun(16:30));
        case 'dot_product_rest_period_3'
            %indices ONLY valid for rest-period data
            prod(run) = dot(faceRun(31:45),sceneRun(31:45));
        case 'dot_product_discard_5'
            %indices ONLY valid for rest-period data
            prod(run) = dot(faceRun([6:15 21:30 36:45]),sceneRun([6:15 21:30 36:45]));
        case 'dot_FS_custom'
            %indices ONLY valid for rest-period data
            FS_custom = 1 - abs(acts.misc{1}.iterations(2).acts(1, beginIndex:endIndex) - acts.misc{1}.iterations(2).acts(2, beginIndex:endIndex));
            prod(run) = dot(faceRun.*FS_custom,sceneRun);
        case 'dot_FS_custom_rest_period_1_2'
            %indices ONLY valid for rest-period data
            FS_custom = 1 - abs(acts.misc{1}.iterations(2).acts(1, 1:30) - acts.misc{1}.iterations(2).acts(2, 1:30));
            prod(run) = dot(faceRun(1:30).*FS_custom,sceneRun(1:30));
        case 'dot_product_rest_period_1_2'
            %indices ONLY valid for rest-period data
            prod(run) = dot(faceRun(1:30),sceneRun(1:30));
        case 'weighted_dot_product'
            %indices ONLY valid for rest-period data
            prod(run) = (sum(faceRun) + sum(sceneRun)) * dot(faceRun,sceneRun);
        case 'boosted_dot_product'
            %indices ONLY valid for rest-period data
            prod(run) = (sum(faceRun) * sum(sceneRun)) + dot(faceRun,sceneRun);
        case 'weighted_average'
            %indices ONLY valid for rest-period data
            weight = faceRun.*sceneRun;
            average = mean([faceRun ; sceneRun]);
            prod(run) = dot(weight,average);
        case 'average_S1_evidence'
            FSweights = zeros(2,1);
            FSweights(s1cat) = 1; % zero weight for s2 evidence
            prod(run) = mean(faceRun * FSweights(1)) + mean(sceneRun * FSweights(2));
        case 'weighted_S1_evidence'
            FSweights = ones(2,1);
            FSweights(s1cat) = 2; % half weight for s2 evidence
            prod(run) = mean(faceRun * FSweights(1)) + mean(sceneRun * FSweights(2));
        case 'average_S2_evidence'
            FSweights = zeros(2,1);
            FSweights(s1cat) = 1; 
            FSweights = ~FSweights; % zero weight for s1 evidence
            prod(run) = mean(faceRun * FSweights(1)) + mean(sceneRun * FSweights(2));
        case 'weighted_S2_evidence'
            FSweights = ones(2,1)*2;
            FSweights(s1cat) = 1; % half weight for s1 evidence
            prod(run) = mean(faceRun * FSweights(1)) + mean(sceneRun * FSweights(2));
        case 'experimental 1'
            FSimmediateweights = zeros(2,1);
            FSimmediateweights(s1cat) = 1; 
            FSimmediateweights = ~FSimmediateweights;
            
            FScounterpartweights = zeros(2,1);
            FScounterpartweights(s1cat) = 1;
            
            loc1Face = acts.face(1,beginIndex:endIndex);
            loc1Scene = acts.scene(1,beginIndex:endIndex);
            loc2Face = acts.face(2,beginIndex:endIndex);
            loc2Scene = acts.scene(2,beginIndex:endIndex);
            
            % immediate from loc 1, counterpart from loc 2
            loc1quant = mean(loc1Face * FSimmediateweights(1)) + mean(loc1Scene * FSimmediateweights(2));
            loc2quant = mean(loc2Face * FScounterpartweights(1)) + mean(loc2Scene * FScounterpartweights(2));
            %loc1quant = (sum(loc1Face) + sum(loc1Scene)) * dot(loc1Face,loc1Scene);
            %loc2quant = (sum(loc2Face) + sum(loc2Scene)) * dot(loc2Face,loc2Scene);
            prod(run) = loc1quant + loc2quant;
        case 'experimental 2'
            loc1Face = acts.face(1,beginIndex:endIndex);
            loc1Scene = acts.scene(1,beginIndex:endIndex);
            loc2Face = acts.face(2,beginIndex:endIndex);
            loc2Scene = acts.scene(2,beginIndex:endIndex);
            prod(run) = dot(loc1Face, loc1Scene) + dot(loc2Face, loc2Scene);
        case 'experimental 3'
            loc1Face = acts.face(1,beginIndex:endIndex);
            loc1Scene = acts.scene(1,beginIndex:endIndex);
            loc2Face = acts.face(2,beginIndex:endIndex);
            loc2Scene = acts.scene(2,beginIndex:endIndex);
            prod(run) = mean(loc1Face + loc2Face) + mean(loc1Scene + loc2Scene);
    end
end

end

