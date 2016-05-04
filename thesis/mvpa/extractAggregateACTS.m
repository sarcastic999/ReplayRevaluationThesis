function [ aggregates ] = extractAggregateACTS(data, aggregationMethod, numRuns, TRs)
% This function takes the classifier outputs (ACTS) and returns the
% aggregate for each run
allRunsLength = numel(data);
% divide into four runs
runLength = allRunsLength/numRuns;
assert(runLength == TRs);
% aggregate separately across runs
aggregates = zeros(1,numRuns);
for i = 1:numRuns
    beginIndex = 1 + (i-1)*runLength;
    endIndex = beginIndex + runLength - 1;
    aggregationFunction = str2func(aggregationMethod);
    aggregate = aggregationFunction(data(beginIndex:endIndex));
    aggregates(i) = aggregate;
end


end

