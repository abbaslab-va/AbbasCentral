function spa_heatmap(peakSpikePhaseByFreq, fSteps)
numSteps = numel(peakSpikePhaseByFreq);
numRadialBins = 13;
circBinEdges = linspace(-pi, pi, numRadialBins + 1);


numNeurons = numel(peakSpikePhaseByFreq{1});
histByFreq = cell(1, numNeurons);
zeros(numRadialBins, numSteps);
for neuron = 1:numNeurons
    histByFreq{neuron} = zeros(numSteps, numRadialBins);
    for freq = 1:numSteps
        histByFreq{neuron}(freq, :) = histcounts(peakSpikePhaseByFreq{freq}{neuron}, circBinEdges);
    end
end

%%
colorScale = [0 500];
colorScheme = 'parula';
% for s = 1:numel(histByFreqPre)
freqLabels = strings(1, numSteps);
for i = 1:numSteps
    freqLabels(i) = sprintf("%.3f - %.3f", fSteps(i), fSteps(i+1));
end
phaseBins = strings(1, numRadialBins);
for i = 1:numRadialBins
    phaseBins(i) = sprintf("%.3f : %.3f", circBinEdges(i), circBinEdges(i+1));
end
freqLabels = flip(freqLabels);
for i = 1:numel(histByFreq)
    figure
    heatmap(flipud(histByFreq{i}), 'GridVisible', 'off', 'YDisplayLabels', freqLabels, 'XDisplayLabels', phaseBins, 'CellLabelColor', 'none')
    colormap(colorScheme)
    ylabel('frequency (hertz)')
    xlabel('phase (radians)')
    title('pre-injection')
end