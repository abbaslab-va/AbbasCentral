function [pwr, phase] = hilbert_power(obj, varargin)

% Calculates power and phase based on the hilbert transform

presets = PresetManager(varargin{:});

if ~isempty(presets.region)
    regionChannels = [];
    if ~iscell(presets.region)
        presets.region = {presets.region};
    end
    for r = 1:numel(presets.region)
        regionStr = presets.region{r};
        regionChannels = [regionChannels obj.info.channels.(regionStr)];
    end
    if isempty(presets.channels)
        presets.channels = regionChannels;
    else
        presets.channels = presets.channels(ismember(presets.channels, regionChannels));
    end
end

if ~iscell(presets.freqBands)
    freqBands = {presets.freqBands};
else
    freqBands = presets.freqBands;
end

numFreqs = numel(freqBands);

if numFreqs == 0
    freqBands = 'default';
    numFreqs = 1;
end

filteredLFP = cell(1, numFreqs);

for f = 1:numFreqs
    fBand = FrequencyRanges(freqBands{f});
    filteredLFP{f} = obj.filter_signal('preset', presets, 'freqLimits', fBand.edges);
end

pwr = cellfun(@(x) cellfun(@(y) abs(hilbert(y')).^2, x, 'uni', 0), filteredLFP, 'uni', 0);
phase = cellfun(@(x) cellfun(@(y) angle(hilbert(y')), x, 'uni', 0), filteredLFP, 'uni', 0);
