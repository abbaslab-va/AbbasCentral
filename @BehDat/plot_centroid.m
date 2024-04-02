function coordCell = plot_centroid(obj, varargin)
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

eventTimes = obj.find_event('preset', presets, 'trialized', false)';

if isempty(eventTimes) || isempty(obj.coordinates)
    coordCell = cell(0, 1);
    return
end

if isfield(obj.info, 'frameRate')
    frameRate = obj.info.frameRate;
else
    frameRate = 30;
end
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'plot', true, @islogical);
parse(p, varargin{:});
doPlot = p.Results.plot;


edges = round(presets.edges * frameRate);
colors = parula(edges(2) - edges(1) + 1);
eventCells = num2cell(edges + eventTimes, 2);
goodEdges = cellfun(@(x) all(x>0) & all(x <= obj.info.samples), eventCells);
eventCells = eventCells(goodEdges);
    
coordCell = cellfun(@(x) obj.coordinates(x(1):x(2), :), eventCells, 'uni', 0);
if ~doPlot
    return
end

if ~isempty(presets.panel)
    h = figure('Visible', 'off');
    hold on
    cellfun(@(x) scatter(x(:, 1), x(:, 2), [], colors, 'filled'), coordCell)
    set(gca, 'color', 'w', 'ydir', 'reverse')
    copyobj(h.Children, presets.panel)
    close(h)
else
    figure;
    hold on
    cellfun(@(x) scatter(x(:, 1), x(:, 2), [], colors, 'filled'), coordCell)
    set(gca, 'color', 'w', 'ydir', 'reverse')
end