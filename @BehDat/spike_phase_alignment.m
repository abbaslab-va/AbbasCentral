function [peakSpikePhaseByFreq, fSteps] = spike_phase_alignment(obj, varargin)
% 
% p = inputParser;
% p.KeepUnmatched = true;
% p.addParameter('channel')
presets = PresetManager(varargin{:});

% iterate over frequencies on exponential grid
fMin = presets.freqLimits(1);
fMax = presets.freqLimits(2);
numSteps = 10;    
zCutoff = 2;
fSteps = [fMin, arrayfun(@(x) fMin * (fMax / fMin)^(x / numSteps), 1:numSteps)];
% regionSpikes = obj.spike_subset(presets);
spikeTimes = obj.bin_all_neurons('preset', presets, 'binWidth', 0.5);

peakSpikePhaseByFreq = cell(1, numSteps);
for freqStartIdx = 1:numSteps
    freqStart = fSteps(freqStartIdx);
    freqEnd = fSteps(freqStartIdx + 1);
    filteredSignal = obj.filter_signal('preset', presets, 'freqLimits', [freqStart freqEnd]);
    
    sessionMean = cellfun(@(x) mean(x, 1, 'omitnan'), filteredSignal, 'uni', 0);
    sessionSTD = cellfun(@(x) std(x, 0, 1), filteredSignal, 'uni', 0);
    filteredZ = cellfun(@(x, y, z) (x - y)./z, ...
        filteredSignal, sessionMean, sessionSTD, 'uni', 0);
    
    trialStart = obj.find_event('preset', presets, 'trialized', true);


    [peakTimes, period] = cellfun(@(x) ...
        find_bandpassed_peaks(x, zCutoff), ...
        filteredZ, 'uni', 0);

    hasPeaks = cellfun(@(x) ~isempty(x), period);
    phaseWithPeaks = cellfun(@(x) angle(hilbert(x)), filteredZ(hasPeaks), 'uni', 0);
    spikesWithPeaks = cellfun(@(x) x(hasPeaks, :), spikeTimes, 'uni', 0);
    peakTimesFiltered = peakTimes(hasPeaks);
    periodFiltered = period(hasPeaks);
    cycleBoundaries = cellfun(@(y, z) ...
            arrayfun(@(a, b) [round(a - .5/b*2000) round(a + .5/b*2000)], ...
                y, z, 'uni', 0), ...
        peakTimesFiltered, periodFiltered, 'uni', 0);
    phaseInPeaks = cellfun(@(y, z) ...
            cellfun(@(p) y(p(1):p(2))', z, 'uni', 0), ...
        phaseWithPeaks, cycleBoundaries, 'uni', 0);

    spikesInPeaks = cellfun(@(neuron) ...
        cellfun(@(peakTrial, neuronTrial) ...
            cellfun(@(p) neuronTrial(p(1):p(2)), ...
                peakTrial, 'uni', 0), ...
            cycleBoundaries, num2cell(neuron, 2), 'uni', 0), ...
        spikesWithPeaks, 'uni', 0);

    peakSpikePhase = cellfun(@(neuron) ...
        cellfun(@(phaseTrial, neuronTrial) ...
            cellfun(@(phaseEvent, neuronEvent) phaseEvent(logical(neuronEvent)), ...
                phaseTrial, neuronTrial, 'uni', 0), ...
            phaseInPeaks, neuron, 'uni', 0), ...
        spikesInPeaks, 'uni', 0);

    peakSpikes = cellfun(@(x) cat(1, x{:}), peakSpikePhase, 'uni', 0);
    peakSpikePhaseByFreq{freqStartIdx} = cellfun(@(x) cat(2, x{:}), peakSpikes, 'uni', 0);
    cycleBoundaries30k = cellfun(@(x) cellfun(@(y) ...
        y*15, x, 'uni', 0), cycleBoundaries, 'uni', 0);
    % 
    % peakAlign = cellfun(@(s, t, u, v) ...
    %     cellfun(@(w, x, y) ...
    %         [w*30000 + x - 1./y * 30000/2, w*30000 + x + 1./y * 30000/2], s(v), t(v)', u(v), 'uni', 0), ...
    %     peakTimes, trialStart, period, hasPeaks, 'uni', 0);

    cycleSamples = cellfun(@(x) ...
            cellfun(@(y) diff(y), x), ...
        cycleBoundaries30k, 'uni', 0);
    % trialStartWithPeaks = trialStart(hasPeaks);
    % cycleCat = cat(1, cycleSamples{:});
    % bEdges = linspace(30000/freqEnd, 30000/freqStart, 20);
    % figure
    % histogram(cycleCat, 'BinEdges', bEdges, 'Normalization', 'probability')
    % title(sprintf('range %d to %d', freqStart, freqEnd))
end
