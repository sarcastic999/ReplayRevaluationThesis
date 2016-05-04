function error_plot_collapse(invecall , xlab_text)

invec    = [ mean(invecall(:,   [1 3]) , 2) mean(invecall(:,   [2 4]) , 2) ];
%probrev  = [ mean(probrevall(:, [1 3]) , 2) mean(probrevall(:, [2 4]) , 2) ];

err=std(invec)/sqrt(length(invec));
figure1 = figure('Color',[1 1 1]);

errorbar(mean(invec), err);

title(xlab_text);
end