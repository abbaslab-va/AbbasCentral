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

if presets.bpod
    eventTimes = obj.find_bpod_event('preset', presets)';
else
    eventTimes = obj.find_event('preset', presets)';
end

if isempty(eventTimes)
    return
end

if ~isfield(obj.info, 'frameRate')
    frameRate = 30;
else
    frameRate = obj.info.frameRate;
end

edges = presets.edges * frameRate;
colors = parula(edges(2) - edges(1) + 1);
eventCells = num2cell(edges + eventTimes, 2);

coordCell = cellfun(@(x) obj.coordinates(x(1):x(2), :), eventCells, 'uni', 0);

if ~isempty(presets.panel)
    h = figure('Visible', 'off');
    hold on
    cellfun(@(x) scatter(x(:, 1), x(:, 2), [], colors, 'filled'), coordCell)
    set(gca, 'color', 'w')
    copyobj(h.Children, presets.panel)
    close(h)
else
    figure;
    hold on
    cellfun(@(x) scatter(x(:, 1), x(:, 2), [], colors, 'filled'), coordCell)
    set(gca, 'color', 'w')
end