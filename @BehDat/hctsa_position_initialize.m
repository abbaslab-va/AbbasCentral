function [timeSeriesData, labels, keywords] = hctsa_position_initialize(obj, presets)

coordinates = obj.plot_centroid('event', presets.event, 'edges', presets.edges, ...
    'offset', presets.offset, 'plot', false);
vidCenter = obj.info.vidRes/2;
leftTrials = obj.bpod.trial_intersection_BpodParser('trialType', 'Left');
rightTrials = obj.bpod.trial_intersection_BpodParser('trialType', 'Right');
correctTrials = obj.bpod.trial_intersection_BpodParser('outcome', 'Correct');
delay1Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay1');
delay2Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay2');
delay3Trials = obj.bpod.trial_intersection_BpodParser('trialType', 'Delay3');
rot1 = rotate_coordinate_data(coordinates(delay1Trials), vidCenter, -2*pi/3);
rot3 = rotate_coordinate_data(coordinates(delay3Trials), vidCenter, 2*pi/3);
coordinates(delay1Trials) = rot1;
coordinates(delay3Trials) = rot3;
negCoords = cellfun(@(x) x <= 0, coordinates, 'uni', 0);
badX = cellfun(@(x) x(:, 1) > obj.info.vidRes(1), coordinates, 'uni', 0);
badY = cellfun(@(y) y(:, 2) > obj.info.vidRes(2), coordinates, 'uni', 0);
for t = 1:numel(coordinates)
    coordinates{t}(negCoords{t}) = 1;
    coordinates{t}(badX{t}, 1) = obj.info.vidRes(1);
    coordinates{t}(badY{t}, 2) = obj.info.vidRes(2);
end

% timeSeriesData = cellfun(@(x) sub2ind(obj.info.vidRes, round(x(:, 1)), round(x(:, 2))), coordinates, 'uni', 0);
% timeSeriesData = cellfun(@(x) sub2ind(obj.info.vidRes, flipud(round(x(:, 1))), round(x(:, 2))), coordinates, 'uni', 0);
timeSeriesData = cellfun(@(x) sub2ind(fliplr(obj.info.vidRes), round(x(:, 2)), round(x(:, 1))), coordinates, 'uni', 0);
timeSeriesData = cellfun(@(x) x - x(1), timeSeriesData, 'uni', 0);
trialNo = num2cell(1:numel(timeSeriesData));
trialString = cellfun(@(x) num2str(x), trialNo, 'uni', 0);
[~, sessName] = fileparts(obj.info.path);
labels = cellfun(@(x) strcat(sessName, '_', x), trialString, 'uni', 0);
keywords = obj.hctsa_keywords('preset', presets);

if numel(keywords) ~= numel(labels) || numel(keywords) ~= numel(timeSeriesData)
    disp('poop')
end

% figure
% set(gca, 'Color', 'w')
% hold on
% cellfun(@(x) scatter(x(:, 1), x(:, 2), 'r'), coordinates(delay1Trials & leftTrials & correctTrials))
% cellfun(@(x) scatter(x(:, 1), x(:, 2), 'b'), coordinates(delay2Trials & leftTrials & correctTrials))
% cellfun(@(x) scatter(x(:, 1), x(:, 2), 'g'), coordinates(delay3Trials & leftTrials & correctTrials))
% cellfun(@(x) scatter(x(:, 1), x(:, 2), 'MarkerFaceColor', [.5 0 0], 'MarkerEdgeColor', [.5 0 0]), coordinates(delay1Trials & rightTrials & correctTrials))
% cellfun(@(x) scatter(x(:, 1), x(:, 2), 'MarkerFaceColor', [0 0 .5], 'MarkerEdgeColor', [0 0 .5]), coordinates(delay2Trials & rightTrials & correctTrials))
% cellfun(@(x) scatter(x(:, 1), x(:, 2), 'MarkerFaceColor', [0 .5 0], 'MarkerEdgeColor', [0 .5 0]), coordinates(delay3Trials & rightTrials & correctTrials))
% figure
% set(gca, 'Color', 'w')
% hold on
% cellfun(@(x) plot(x, 'r'), timeSeriesData(delay1Trials & leftTrials & correctTrials))
% cellfun(@(x) plot(x, 'b'), timeSeriesData(delay2Trials & leftTrials & correctTrials))
% cellfun(@(x) plot(x, 'g'), timeSeriesData(delay3Trials & leftTrials & correctTrials))
% cellfun(@(x) plot(x, 'Color', [.5 0 0]), timeSeriesData(delay1Trials & rightTrials & correctTrials))
% cellfun(@(x) plot(x, 'Color', [0 0 .5]), timeSeriesData(delay2Trials & rightTrials & correctTrials))
% cellfun(@(x) plot(x, 'Color', [0 .5 0]), timeSeriesData(delay3Trials & rightTrials & correctTrials))
% 
% timeSeriesData = timeSeriesData(correctTrials);
% labels = labels(correctTrials);
% keywords = keywords(correctTrials);

% timeSeriesData = timeSeriesData(leftTrials);
% labels = labels(leftTrials);
% keywords = keywords(leftTrials);
% % 
timeSeriesData = timeSeriesData(rightTrials);
labels = labels(rightTrials);
keywords = keywords(rightTrials);