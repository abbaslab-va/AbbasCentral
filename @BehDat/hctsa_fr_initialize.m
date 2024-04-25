function [timeSeriesData, labels, keywords] = hctsa_fr_initialize(obj, presets)

% timeSeriesData = obj.bin_all_neurons('preset', presets);
timeSeriesData = obj.z_score('preset', presets, 'eWindow', presets.edges, 'binWidth', 20);
timeSeriesData = num2cell(timeSeriesData, 2);
trialNo = num2cell(1:numel(timeSeriesData));
trialString = cellfun(@(x) num2str(x), trialNo, 'uni', 0);
[~, sessName] = fileparts(obj.info.path);
labels = cellfun(@(x) strcat(sessName, '_', x), trialString, 'uni', 0);
keywords = extractfield(obj.spikes, 'region');
% keywords = obj.hctsa_keywords('preset', presets);