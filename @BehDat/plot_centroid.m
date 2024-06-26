function [trializedLocation, figH]  = plot_centroid(obj, varargin)
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
    trializedLocation = cell(0, 1);
    return
end

if isfield(obj.info, 'frameRate')
    frameRate = obj.info.frameRate;
else
    frameRate = 30;
    warning('No frame rate supplied by object - defaulting to 30 fps')
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
    
trializedLocation = cellfun(@(x) obj.coordinates(x(1):x(2), :), eventCells, 'uni', 0);
if ~doPlot
    return
end

% vidCenter = obj.info.vidRes/2;
% delay1Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay1');
% delay3Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay3');
% rot1 = rotate_coordinate_data(trializedLocation(delay1Trials), vidCenter, -2*pi/3);
% rot3 = rotate_coordinate_data(trializedLocation(delay3Trials), vidCenter, 2*pi/3);
% trializedLocation(delay1Trials) = rot1;
% trializedLocation(delay3Trials) = rot3;

if ~isempty(presets.panel)
    figH = figure('Visible', 'off');
    hold on
    cellfun(@(x) scatter(x(:, 1), x(:, 2), [], colors, 'filled'), trializedLocation)
    set(gca, 'color', 'w', 'ydir', 'reverse')
    copyobj(figH.Children, presets.panel)
    close(figH)
else
    figH = figure;
    hold on
    cellfun(@(x) scatter(x(:, 1), x(:, 2), [], colors, 'filled'), trializedLocation)
    set(gca, 'color', 'w', 'ydir', 'reverse')
end