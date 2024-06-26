function [trializedBehavior, numericalBehavior, figH] = plot_LabGym_behaviors(obj, varargin)

presets = PresetManager(varargin{:});

p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'plot', true, @islogical);
parse(p, varargin{:});
doPlot = p.Results.plot;

keypoints = obj.find_event('preset', presets, 'trialized', false);

if isfield(obj.info, 'frameRate')
    frameRate = obj.info.frameRate;
else
    frameRate = 30;
end

edges = round(presets.edges * frameRate);
numFrames = numel(obj.LabGym);

frameEdges = num2cell(edges + keypoints', 2);
inBounds = cellfun(@(x) x(1) > 0 && x(2) <= numFrames, frameEdges);
goodFrames = frameEdges(inBounds);
trializedBehavior = cellfun(@(x) obj.LabGym(x(1):x(2)), goodFrames, 'uni', 0);

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

custom_colormap = brewermap(9, 'Accent');

trializedBehaviorMat = cat(2, trializedBehavior{:})';
numericalBehavior = zeros(size(trializedBehaviorMat));
if isempty(trializedBehaviorMat)
    return;
end
allCats = categories(obj.LabGym);
for c = 1:numel(allCats)
    inds = trializedBehaviorMat == allCats{c};
    numericalBehavior(inds) = c;
end

if ~doPlot
    figH = [];
    return
end

if isempty(presets.panel)
    figH = figure;
else
    figH = figure('Visible', 'off');
end

heatmap(figH, numericalBehavior, 'GridVisible', 'off', 'CellLabelColor', 'none')
colormap(custom_colormap);
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