function [ acts, mdp_conditions_order, s1categories ] = getActs( subject, class_args, roi, localizer_tag, prefix)
if isempty(getenv('SGE_DATAPATH'))
    datapath = '/usr/people/erhee/thesis/mvpa'; %default data path
    setenv('SGE_DATAPATH', '/usr/people/erhee/thesis/mvpa');
else
    datapath = getenv('SGE_DATAPATH');
end
if isempty(getenv('SGE_MVPA_ONLY'))
    mvpa_only = 0;
else
    mvpa_only = str2num(getenv('SGE_MVPA_ONLY'));
end
if(~isempty(getenv('LOC2TRSHIFT')))
    loc2_shiftTRs = str2num(getenv('LOC2TRSHIFT'));
else
    loc2_shiftTRs = 3;
end
% Delete Last TR? -- see mvpa_Loc1XLoc2_3set_predction_accuracies.m for motivation into why 3rd TR is not good.
if(~isempty(getenv('LOC2TR')))
    loc2_numTRs = str2num(getenv('LOC2TR')); % use first x TRs only
else
    loc2_numTRs = 3;
end
    
jsonrep = savejson('',class_args);
comma_indices = find(jsonrep == ',');
if numel(comma_indices) >1
    custom_param_begin_index = comma_indices(2)+1;
    unprocessed_params = jsonrep(custom_param_begin_index:end);
    processed_params = regexprep(regexprep(unprocessed_params,'\n|\t|}|\"',''),': ','_');
else
    processed_params = '';
end

switch (roi)
    case 'FFA_PPA'
        switch(localizer_tag)
            case '1'
                localizer_set = [1];
            case '2'
                localizer_set = [2];
            case '12'
                localizer_set = [12];
            case '21'
                localizer_set = [1, 2];
        end
        for localizer = localizer_set
            index = find(localizer_set == localizer);
            rootPath = sprintf('%s/MVPA_%s_Face_Scene', datapath, prefix);
            if localizer == 1
                filePath = sprintf('%s/Loc%dX%s_subject%d_%s_%s_%s.mat', rootPath, localizer, prefix, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
            elseif localizer == 2 || localizer == 12 
                filePath = sprintf('%s/Loc%dShift%d_%dTRsX%s_subject%d_%s_%s_%s.mat', rootPath, localizer, loc2_shiftTRs, loc2_numTRs, prefix, subject, class_args.train_funct_name, class_args.test_funct_name, processed_params) ;
            end
            function_name = sprintf('mvpa_Loc%dX%s_Face_Scene', localizer,prefix);
            mvpa_func = str2func(function_name);
            % if file doesn't exist, MVPA analysis hasn't been run yet.
            if ~(exist(filePath, 'file') == 2)
                disp(['missing:' filePath]);
                mvpa_func(subject, class_args);
            end
            disp(['found: ' filePath]);
            if mvpa_only % hacky way of bypassing everything else
                acts = [];
                mdp_conditions_order = [];
                s1categories = [];
                continue;
            end
            clear results;
            load(filePath);

            if ~(exist('imregs')) % initial analyses for Rest periods did not include this.
                imregs{1}.conds = ones(1,45);
                imregs{2}.conds = ones(1,45);
                imregs{3}.conds = ones(1,45);
                imregs{4}.conds = ones(1,45);
            end
            if (localizer == 1 || (localizer == 2 && subject > 4) || (localizer == 12 && subject > 4))
                %% Reorder to match condition order
                mvpa_FFAPPA2cat     = '/jukebox/norman/reprev/results_mvpa/FFAPPA_loc1Xrest/';
                file1 = [ mvpa_FFAPPA2cat 'S' num2str(subject) '_loc1Xrest.mat'] ;
                load(file1);
                mdp_conditions_order = meanRunMdp(1,:);
                mdp_S1 = meanRunMdp(3,:);
                runLengths = [numel(find(imregs{1}.conds == 1)) numel(find(imregs{2}.conds == 1)) numel(find(imregs{3}.conds == 1)) numel(find(imregs{4}.conds == 1))];

                ordered_cats = sortrows([mdp_conditions_order;mdp_S1]')';
                s1categories = ordered_cats(2,:);
                for run = 1:4
                    mdpindex = mdp_conditions_order(run);
                    mdpPositionBegin = 1;
                    for i = 1 : mdpindex - 1
                        mdpPositionBegin = mdpPositionBegin + runLengths(find(mdp_conditions_order==i));
                    end
                    mdpPositionEnd = mdpPositionBegin + runLengths(find(mdp_conditions_order==mdpindex)) - 1;
                    mdpIndexBegin(run) = mdpPositionBegin;
                    mdpIndexEnd(run) = mdpPositionEnd;
                end
                actsPositionEnd = 0;            
                for run = 1:4
                    actsPositionBegin = actsPositionEnd+1;
                    actsPositionEnd = actsPositionBegin + numel(find(imregs{run}.conds == 1)) - 1;
                    acts.face(index,mdpIndexBegin(run):mdpIndexEnd(run)) = results{1}.iterations(2).acts(1,actsPositionBegin:actsPositionEnd);
                    acts.scene(index,mdpIndexBegin(run):mdpIndexEnd(run)) = results{2}.iterations(2).acts(2,actsPositionBegin:actsPositionEnd);
                    if numel(results) > 2
                        for i = 3:numel(results)
                            acts.misc{index,i-2} = results{i};
                        end
                    end
                    acts.s1(index,:) = mdp_S1;
                end
                acts.run_lengths(index,:) = runLengths(mdp_conditions_order);

            else
                acts = [];
            end
        end
    case 'MOTOR'
end

