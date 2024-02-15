function figH = plot_centroid_and_behaviors(obj, varargin)

% 
% This function plots the coordinates stored in the object's coordinate
% property around an event specified using a PresetManager.
% OUTPUT:
%     figH - figure handle to the plot
% INPUT:
%     varargin - event, trialType, outcome, trials, offset, bpod
%     edges need to be standardized, as there is not a place yet in the
%     object that stores the video frame rate. could go in obj.info

presets = PresetManager(varargin{:});

if presets.bpod
    eventTimes = obj.find_bpod_event('preset', presets)';
else
    eventTimes = obj.find_event('preset', presets)';
end

if isempty(eventTimes)
    return
end

if isfield(obj.info, 'frameRate')
    frameRate = obj.info.frameRate;
else
    frameRate = 30;
end
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'fig', [], @ishandle)
parse(p, varargin{:});
if ~isempty(p.Results.fig)
    figH = p.Results.fig;
else
    figH = figure;
end

custom_colormap = ...
    [0.3 0.3 0.3; ...   NA - dark grey
    0 0 1; ...          drink - blue
    0 0 0; ...          groom - black
    1 0 0; ...          left - red
    1 1 1; ...          poke - white
    1 1 0; ...          rear - yellow
    0.7 0.7 0.7; ...    rest - light grey
    0 1 0; ...          right - green
    1 .5 0; ...         walk - purple
    ];


edges = round(presets.edges * frameRate);
eventCells = num2cell(edges + eventTimes, 2);
goodEdges = cellfun(@(x) all(x>0) & all(x <= obj.info.samples), eventCells);
eventCells = eventCells(goodEdges);
    
coordCell = cellfun(@(x) obj.coordinates(x(1):x(2), :), eventCells, 'uni', 0);



edges = round(presets.edges * frameRate);
numFrames = numel(obj.LabGym);

frameEdges = num2cell(edges + eventTimes, 2);
inBounds = cellfun(@(x) x(1) > 0 && x(2) <= numFrames, frameEdges);
goodFrames = frameEdges(inBounds);
trializedBehavior = cellfun(@(x) obj.LabGym(x(1):x(2)), goodFrames, 'uni', 0);


trializedBehaviorMat = cat(2, trializedBehavior{:})';
f = zeros(size(trializedBehaviorMat));
allCats = categories(trializedBehaviorMat);
for c = 1:numel(allCats)
    inds = trializedBehaviorMat == allCats{c};
    f(inds) = c;
end
f = num2cell(f, 2);
if ~isempty(presets.panel)
    hold on
    figH.Visible = 'off';
    cellfun(@(x, y) scatter(x(:, 1), x(:, 2), [], custom_colormap(y, :), 'filled'), coordCell, f)
    set(gca, 'color', 'w', 'ydir', 'reverse')
    copyobj(figH.Children, presets.panel)
    close(figH)
else
    hold on
    cellfun(@(x, y) scatter(x(:, 1), x(:, 2), [], custom_colormap(y, :), 'filled'), coordCell, f)
    set(gca, 'color', 'w', 'ydir', 'reverse')
end

