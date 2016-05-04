function [aggregate] = performAggregation(method, values)

switch(method)
    case 'average'
        aggregate = mean(values);
    otherwise
        fprintf('aggregation function %s is undefined', method);
end

end