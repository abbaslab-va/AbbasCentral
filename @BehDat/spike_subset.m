function whichNeurons = spike_subset(obj, presets)

neuronIdx = 1:numel(obj.spikes);
if ~isempty(presets.subset)
    neuronsInSubset = ismember(neuronIdx, presets.subset);
else
    neuronsInSubset = true(size(neuronIdx));
end

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

whichNeurons = neuronsInSubset & neuronsInRegion & neuronsWithLabel;