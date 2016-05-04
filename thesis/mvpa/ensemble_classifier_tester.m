% Use with Breakpoints at  mvpa_Loc1XLoc2_Face_Scene.m

%% Face, Training on Loc 2 Testing on Loc 1
mask = 1;
testData = subj.patterns{2+mask}.mat(:,find(subj.selectors{3}.mat == 2));
trainData = subj.patterns{2+mask}.mat(:,find(subj.selectors{3}.mat == 1));
trainlabels = subj.regressors{1}.mat(mask,find(subj.selectors{3}.mat == 1));
testlabels = subj.regressors{1}.mat(mask,find(subj.selectors{3}.mat == 2));
testData = testData';
trainData = trainData';

%% Scene, Training on Loc 2 Testing on Loc 1
mask = 2;
testData = subj.patterns{2+mask}.mat(:,find(subj.selectors{3}.mat == 2));
trainData = subj.patterns{2+mask}.mat(:,find(subj.selectors{3}.mat == 1));
trainlabels = subj.regressors{1}.mat(mask,find(subj.selectors{3}.mat == 1));
testlabels = subj.regressors{1}.mat(mask,find(subj.selectors{3}.mat == 2));
testData = testData';
trainData = trainData';

%% Face, Training on Loc 1 Testing on Loc 2
mask = 1;
testData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 2));
trainData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 1));
trainlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 1));
testlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 2));
testData = testData';
trainData = trainData';

%% Scene, Training on Loc 1 Testing on Loc 2
mask = 2;
testData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 2));
trainData = subj.patterns{2+mask}.mat(:,find(subj.selectors{4}.mat == 1));
trainlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 1));
testlabels = subj.regressors{1}.mat(mask,find(subj.selectors{4}.mat == 2));
testData = testData';
trainData = trainData';


%% Random Forests - 0.9375
nTrees = 500;
rf = TreeBagger(nTrees,trainData,trainlabels, 'Method', 'classification');
results = rf.predict(testData);
err = 0;
for ind = 1:numel(results);
    pred = str2num(results{ind});
    real = testlabels(ind);
    if (pred ~= real)
        err = err+1;
    end
end
perf = 1 - err/numel(results)

%% AdaBoost
ada = fitensemble(trainData,trainlabels,'AdaBoostM1',...
    500,'Tree','LearnRate',0.1);
results = ada.predict(testData);
err = 0;
for ind = 1:numel(results);
    pred = results(ind);
    real = testlabels(ind);
    if (pred ~= real)
        err = err+1;
    end
end
perf = 1 - err/numel(results)

%% RobustBoost
rb = fitensemble(trainData,trainlabels,'RobustBoost',500,...
   'Tree','RobustErrorGoal',0.01,'RobustMaxMargin',1);
results = rb.predict(testData);
err = 0;
for ind = 1:numel(results);
    pred = results(ind);
    real = testlabels(ind);
    if (pred ~= real)
        err = err+1;
    end
end
perf = 1 - err/numel(results)