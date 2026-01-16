function ppc_harmonic_structure(obj, varargin)

presets = PresetManager(varargin{:});
[phases, freqs] = obj.spike_phase_alignment('preset', presets);
freqTolerance = 1e-6;
numFreqs = numel(freqs);
baseIdx = 1:numFreqs;
k = 2:5;        % harmonic integers
harmonicIdx = cell(size(k));
[harmonicIdx{:}] = deal(nan(size(baseIdx)));
whichNeurons = obj.spike_subset(presets);
numNeurons = sum(whichNeurons);
phaseVec = cell(1, numNeurons);
numNeurons = numel(phases{1});
for neuron = 1:numNeurons
    neuronVec = cellfun(@(x) x{neuron}, phases, 'uni', 0);
    phaseVec{neuron} = cat(2, neuronVec{:})';
end
for b = baseIdx
    targetFreq = arrayfun(@(x) x * freqs(b), k);
    [err, idx] = arrayfun(@(x) min(abs(freqs - x)), targetFreq);
    validIdx = arrayfun(@(x) x < freqTolerance, err);
    if any(validIdx)
        harmonic = find(validIdx);
        for h = 1:numel(harmonic)
            hVal = harmonic(h);
            harmonicIdx{hVal}(b) = idx(hVal);
        end
    end
end
disp('poop')