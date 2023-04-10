function [f, h] = rotation_surf(angleMat, panel)

% This function plots trialized rotation in a bpod task, using video from
% the whitematter e3vision setup.
% INPUT:
%     movementMat - the output from a call to trialize_rotation

cmap = parula;
f = figure;
h = heatmap(angleMat, 'ColorMap', cmap, 'GridVisible', 'off', 'ColorLimits', [-3 3]);

h.XDisplayLabels = repmat({''}, size(h.XData));
h.YDisplayLabels = repmat({''}, size(h.YData));

a2 = axes('Position', h.Position);
a2.Color = 'none';
a2.YTick = [0, 1];
a2.YTickLabel = {};
a2.XTick = [0, .2, .4, .6, .8, 1];
a2.XTickLabel = {};
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out');
ax=gca;
ax.LineWidth=1.5;

if exist('panel', 'var')
%     f = figure('Visible', 'off');
%     h = heatmap(angleMat, 'ColorMap', cmap, 'GridVisible', 'off', 'ColorLimits', [-3 3]);
%     h.XDisplayLabels = repmat({''}, size(h.XData));
%     h.YDisplayLabels = repmat({''}, size(h.YData));
    copyobj(f.Children, panel)
    close(f)
%     return
end