function [timeSeriesData, labels, keywords] = hctsa_position_initialize(obj, presets)

coordinates = obj.plot_centroid('event', presets.event, 'edges', presets.edges, ...
    'offset', presets.offset, 'plot', false);
vidCenter = obj.info.vidRes/2;
% delay2Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay2');
% delay3Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay3');
% rot2 = rotate_coordinate_data(coordinates(delay2Trials), vidCenter, 2*pi/3);
% rot3 = rotate_coordinate_data(coordinates(delay3Trials), vidCenter, 4*pi/3);
% coordinates(delay2Trials) = rot2;
% coordinates(delay3Trials) = rot3;
badCoords = cellfun(@(x) x == 0, coordinates, 'uni', 0);
for t = 1:numel(coordinates)
    coordinates{t}(badCoords{t}) = 1;
end
timeSeriesData = cellfun(@(x) sub2ind(obj.info.vidRes, round(x(:, 1)), round(x(:, 2))), coordinates, 'uni', 0);
trialNo = num2cell(1:numel(timeSeriesData));
trialString = cellfun(@(x) num2str(x), trialNo, 'uni', 0);
[~, sessName] = fileparts(obj.info.path);
labels = cellfun(@(x) strcat(sessName, '_', x), trialString, 'uni', 0);
keywords = obj.hctsa_keywords('preset', presets);

if numel(keywords) ~= numel(labels) || numel(keywords) ~= numel(timeSeriesData)
    disp('poop')
end