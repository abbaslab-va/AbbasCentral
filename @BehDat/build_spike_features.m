function spikeFeatures = build_spike_features(obj, presets)

% Builds a dictionary of features for feature tables.

if isempty(presets.region)
    if isfield(obj.info, 'regions')
        allRegions = fieldnames(obj.info.regions);
    else
        allRegions = unique(extractfield(obj.spikes, 'region'));
    end
else
    allRegions = presets.region;
end

spikeRegions = strings(1, numel(allRegions));
rateByRegion = cell(1, numel(allRegions));

for r = 1:numel(allRegions)
    region = allRegions{r};
    spikeRegions(r) = ['spikeRate', region];
    spikeRate = obj.bin_all_neurons('preset', presets, 'region', region, 'binWidth', 1000 * diff(presets.edges));
    spikeRate = cat(2, spikeRate{:});
    rateByRegion{r} = mean(spikeRate, 2);
end

spikeFeatures = dictionary(spikeRegions, rateByRegion);