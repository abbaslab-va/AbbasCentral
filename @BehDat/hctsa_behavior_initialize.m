function [timeSeriesData, labels, keywords] = hctsa_behavior_initialize(obj, presets)

[~, timeSeriesData] = obj.plot_LabGym_behaviors('event', presets.event, 'edges', presets.edges, ...
    'offset', presets.offset, 'plot', false);

trialNo = num2cell(1:size(timeSeriesData, 1));
trialString = cellfun(@(x) num2str(x), trialNo, 'uni', 0);
[~, sessName] = fileparts(obj.info.path);
labels = cellfun(@(x) strcat(sessName, '_', x), trialString, 'uni', 0);
keywords = obj.hctsa_keywords('preset', presets);

