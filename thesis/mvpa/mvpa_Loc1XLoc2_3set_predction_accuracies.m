VALID_SUBJECTS = [5:9 11:23 25:26];
mask = 1;
shiftTRs = 3;
for s = VALID_SUBJECTS
    load(sprintf('/usr/people/erhee/thesis/mvpa/MVPA_LOCALIZER_Face_Scene/Loc1XLoc2Shift%d_subject%d_train_L2_RLR_test_L2_RLR_penalty_5.mat',shiftTRs,s));
    accuracies(find(VALID_SUBJECTS==s),:) = sum(reshape(results{mask}.iterations(2).perfmet.corrects,3,24)')/24;
end
disp(accuracies);
figure;
 plot([1:20],accuracies')
 legend('TR1', 'TR2', 'TR3');
 title(sprintf('Train:Loc1 Test:Loc2Shift%dAccuracies for mask %d L2 RLR penalty 5 for each 3TR-training sets',shiftTRs,mask));
 xlabel('Subject');
 ylabel('Accuracy')
 
[h p ci stats] = ttest2(accuracies(:,1), accuracies(:,2))
[h p ci stats] = ttest2(accuracies(:,1), accuracies(:,3))
[h p ci stats] = ttest2(accuracies(:,2), accuracies(:,3))
axis([1,20,0,1]);