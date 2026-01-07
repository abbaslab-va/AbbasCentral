function [spikePhaseByFreq, fSteps] = spike_phase_alignment(obj, varargin)
% 
% p = inputParser;
% p.KeepUnmatched = true;
% p.addParameter('channel')
presets = PresetManager(varargin{:});

% iterate over frequencies on exponential grid
fMin = presets.freqLimits(1);
fMax = presets.freqLimits(2);
numSteps = 10;    
fSteps = [fMin, arrayfun(@(x) fMin * (fMax / fMin)^(x / numSteps), 1:numSteps)];
% regionSpikes = obj.spike_subset(presets);
spikeTimes = obj.bin_all_neurons('preset', presets, 'binWidth', 0.5);
spikeTimes = cellfun(@(x) num2cell(logical(x), 2), spikeTimes, 'uni', 0);
spikePhaseByFreq = cell(1, numSteps);
for freqStartIdx = 1:numSteps
    freqStart = fSteps(freqStartIdx);
    freqEnd = fSteps(freqStartIdx + 1);
    goodChannels = obj.test_channel_phase_coherence('preset', presets);
    filteredSignal = obj.filter_signal('preset', presets, 'freqLimits', [freqStart freqEnd], 'channels', goodChannels);

    phase = cellfun(@(x) angle(hilbert(mean(x, 2))), filteredSignal, 'uni', 0);

    spikePhase = cellfun(@(x) cellfun(@(y, z) ...
        y(z'), phase, x, 'uni', 0), spikeTimes, 'uni', 0);
    peakSpikes = cellfun(@(x) cat(1, x{:}), spikePhase, 'uni', 0);
    spikePhaseByFreq{freqStartIdx} = peakSpikes;
end
