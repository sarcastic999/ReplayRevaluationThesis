function [cats] = getS1cat(subject)
    filename   = ['/jukebox/norman/reprev/behavioral/newS' num2str(subject) '/run1.mat'];
    load(filename);
    cats        = exp.cityJuxt;
end