function [figH, lineH, shadeH]=shaded_error_plot(x,means,sem,linecolor,shadecolor,alpha, figH)
    x=reshape(x,length(x),1);
    means=reshape(means,length(means),1);
    sem=reshape(sem,length(sem),1);
    if ~exist('figH', 'var')
        figH = figure;
    end
    shadeH = fill([x;x(end:-1:1)],[means-sem;means(end:-1:1)+sem(end:-1:1)],shadecolor,'edgecolor',shadecolor,'facealpha',alpha,'edgealpha',alpha);
    hold on
    if alpha <= .3
        lineStyle = '-';
    else
        lineStyle = '--';
    end
    lineH = semilogx(x,means,'color',linecolor,'LineWidth',3, 'LineStyle', lineStyle);hold on
end