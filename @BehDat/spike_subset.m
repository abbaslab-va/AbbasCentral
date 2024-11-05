function whichNeurons = spike_subset(obj, presets)

% subset from presets
neuronIdx = 1:numel(obj.spikes);
if ~isempty(presets.subset)
    neuronsInSubset = ismember(neuronIdx, presets.subset);
else
    neuronsInSubset = true(size(neuronIdx));
end
% regions
if ~isempty(presets.region)
    if ischar(presets.region)
        regionCell = {presets.region};
    elseif iscell(presets.region)
        regionCell = presets.region;
    end
    neuronsInRegion = cellfun(@(x) cellfun(@(y) ...
        strcmp(y, x), extractfield(obj.spikes, 'region')), ...
        regionCell, 'uni', 0);
    neuronsInRegion = cat(1, neuronsInRegion{:});
    neuronsInRegion = any(neuronsInRegion, 1);
else
    neuronsInRegion = true(size(neuronIdx));
end
% spike labels
if ~isempty(presets.label)
    if ischar(presets.label)
        labelCell = {presets.label};
    elseif iscell(presets.label)
        labelCell = presets.label;
    end
    neuronsWithLabel = cellfun(@(x) cellfun(@(y) ...
        strcmp(y, x), extractfield(obj.spikes, 'label')), ...
        labelCell, 'uni', 0);
    neuronsWithLabel = cat(1, neuronsWithLabel{:});
    neuronsWithLabel = any(neuronsWithLabel, 1);
else
    neuronsWithLabel = true(size(neuronIdx));
end
% minimum firing rate
firingRates = extractfield(obj.spikes, 'fr');
if ~isempty(presets.minFR)
    neuronsAboveThreshold = firingRates >= presets.minFR;
else
    neuronsAboveThreshold = true(size(neuronIdx));
end
% maximum firing rate
if ~isempty(presets.maxFR)
    neuronsBelowThreshold = firingRates <= presets.maxFR;
else
    neuronsBelowThreshold = true(size(neuronIdx));
end
% intersect neuron subsets across conditions
whichNeurons = ...
    neuronsInSubset & ...
    neuronsInRegion & ...
    neuronsWithLabel & ...
    neuronsAboveThreshold & ...
    neuronsBelowThreshold;