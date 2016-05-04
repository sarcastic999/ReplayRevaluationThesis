function error_plot_sucfail(invec , xlab_text)
err=std(invec)/sqrt(length(invec));
figure1 = figure('Color',[1 1 1]);

%errorbar(mean(invec), err);

makeFig_bar_4mdp(mean(invec), err); % ida's configs


title(xlab_text);
end