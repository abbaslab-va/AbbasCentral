function [trializedBehavior, numericalBehavior, figH] = plot_combined_behaviors(obj, varargin)

presets = PresetManager(varargin{:});

p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'plot', true, @islogical)
parse(p, varargin{:});
doPlot = p.Results.plot;

whichSessions = obj.subset('animal', presets.animals);

[trializedBehaviorAll, numericalBehaviorAll] = arrayfun(@(x) x.plot_LabGym_behaviors('preset', presets, 'plot', false), obj.sessions(whichSessions), 'uni', 0);

trializedBehavior = cat(1, trializedBehaviorAll{:});
numericalBehavior = cat(1, numericalBehaviorAll{:});

if ~doPlot
    figH = [];
    return
end


% custom_colormap = ...
%     [0.3 0.3 0.3; ...   NA - dark grey
%     0 0 1; ...          drink - blue
%     0 0 0; ...          groom - black
%     1 0 0; ...          left - red
%     1 1 1; ...          poke - white
%     1 1 0; ...          rear - yellow
%     0.7 0.7 0.7; ...    rest - light grey
%     0 1 0; ...          right - green
%     1 .5 0; ...         walk - purple
%     ];
defaultColormap = brewermap(9, 'Set1');
customColormap = ...
    [0 0 0;
    defaultColormap(2, :);
    defaultColormap(6, :);
    defaultColormap(1, :);
    defaultColormap(8, :);
    defaultColormap(5, :);
    defaultColormap(9, :);
    defaultColormap(3, :);
    defaultColormap(7, :);
    ];

trializedBehaviorMat = cat(2, trializedBehavior{:})';

if isempty(trializedBehaviorMat)
    return;
end

allCats = arrayfun(@(x) categories(x.LabGym), obj.sessions, 'uni', 0);
allCats = cat(1, allCats{:});
allCats = unique(allCats);
if isempty(presets.panel)
    figH = figure;
else
    figH = figure('Visible', 'off');
end
heatmap(figH, numericalBehavior, 'GridVisible', 'off', 'CellLabelColor', 'none')
colormap(customColormap);
Ax = gca;
Ax.XDisplayLabels = nan(size(Ax.XDisplayData));
Ax.YDisplayLabels = nan(size(Ax.YDisplayData));
axs = struct(Ax); %ignore warning that this should be avoided
cb = axs.Colorbar;
cb.TickLabels = allCats;


if ~isempty(presets.panel)
    copyobj(figH.Children, presets.panel)
    close(figH)
end
