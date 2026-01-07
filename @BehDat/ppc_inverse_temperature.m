function tempMagnitudeByNeuron = ppc_inverse_temperature(obj, varargin)

presets = PresetManager(varargin{:});
[phases, freqs] = obj.spike_phase_alignment('preset', presets);

numFreqs = numel(freqs);
whichNeurons = obj.spike_subset(presets);
numNeurons = sum(whichNeurons);
phaseVec = cell(1, numNeurons);
numNeurons = numel(phases{1});
for neuron = 1:numNeurons
    for neuron = 1:numNeurons
        neuronVec = cellfun(@(x) x{neuron}, phases, 'uni', 0);
         phaseVec{neuron} = cat(2, neuronVec{:})';
        % for one spike: m = 1/B * sum(exp(1i * phase)) for every phase
    end
end
% complex number = 1/numPhases * 
phaseTemps = cellfun(@(x) arrayfun(@(y) exp(1i * y), x), phaseVec, 'uni', 0);
tempMagnitudeByNeuron = cellfun(@(x) abs(mean(x, 2)), phaseTemps, 'uni', 0);
        % for spike in neuron
        %     put spike in phase vector with phase for every freq
        % find freqs that have phase consistency
        % the harmonic intervals should be integrated into another method
        % these will estimate convergence of a finite ppc value across
        % multiple harmonic series and categorize their coherence in
        % octaves, cubics, and quartic harmonic intervals