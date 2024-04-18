function [timeSeriesData, labels, keywords] = hctsa_position_initialize(obj, presets)

coordinates = obj.plot_centroid('event', presets.event, 'plot', false);
badCoords = cellfun(@(x) x == 0, coordinates, 'uni', 0);
for t = 1:numel(coordinates)
    coordinates{t}(badCoords{t}) = 1;
end
timeSeriesData = cellfun(@(x) sub2ind(obj.info.vidRes, round(x(:, 1)), round(x(:, 2))), coordinates, 'uni', 0);
trialNo = num2cell(1:numel(timeSeriesData));
trialString = cellfun(@(x) num2str(x), trialNo, 'uni', 0);
labels = cellfun(@(x) strcat(obj.info.name, '_', x), trialString, 'uni', 0);
keywords = obj.hctsa_keywords('preset', presets);