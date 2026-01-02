function [ppc, sigCells, fSteps] = spa_ppc(obj, varargin)

presets = PresetManager(varargin{:});
[peakSpikePhaseByFreq, fSteps] = obj.spike_phase_alignment('preset', presets);
numBins = numel(fSteps) - 1;
numCells = numel(peakSpikePhaseByFreq{1});
enoughSpikes = cellfun(@(x) cellfun(@(y) numel(y) > 100, x), peakSpikePhaseByFreq, 'uni', 0);
peakPhase = arrayfun(@(x) deal(cell(1, numCells)), 1:numBins, 'uni', 0);
peakPhaseFiltered = cellfun(@(y, z) y(z), peakSpikePhaseByFreq, enoughSpikes, 'uni', 0);
sigPhase = cellfun(@(x) cellfun(@(y) circ_rtest(y), x), peakPhaseFiltered, 'uni', 0);
for i = 1:numel(peakPhase)
    freqIdx = enoughSpikes{i};
    peakPhase{i}(freqIdx) = num2cell(sigPhase{i});
end
sigCells = cellfun(@(x) cellfun(@(y) ...
    ~isempty(y) && y < 0.05, x), peakPhase, 'uni', 0);
peakPhaseFiltered = cellfun(@(y, z) y(z), peakSpikePhaseByFreq, sigCells, 'uni', 0);
% numEvents = numel(peakPhaseFiltered);
% parfor i = 1:numel(peakPhaseFiltered)
%     peakEvent = peakPhaseFiltered{i};
%     ppc{i} = mean(nonzeros(triu(cos(z.'-z), 1)))
% end
ppc = cellfun(@(y) cellfun(@(z) mean(nonzeros(triu(cos(z.'-z), 1))), y), peakPhaseFiltered, 'uni', 0);
