function s = processed_param_string(class_args)
     jsonrep = savejson('',class_args);
     comma_indices = find(jsonrep == ',');
     custom_param_begin_index = comma_indices(2)+1;
     unprocessed_params = jsonrep(custom_param_begin_index:end);
     s = regexprep(regexprep(unprocessed_params,'\n|\t|}|\"',''),': ','_');
end