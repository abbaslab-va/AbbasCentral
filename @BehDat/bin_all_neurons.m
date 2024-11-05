function binnedNeurons = bin_all_neurons(obj, varargin)

% OUTPUT:
%     binnedNeurons - a 1xN cell where N is the number of neurons in the
%     session, each cell containing an ExT binary matrix of spike times for
%     that neuron where E is the number of events and T is the number of
%     timepoints with the given edges and binWidth. If binWidth is set
%     larger than 1 (ms), it will no longer be a binary matrix.
% INPUT: 
% optional name/value pairs:
%     event -  an event character vector found in the config.ini file (default is trialStart)
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1

presets = PresetManager(varargin{:});
whichNeurons = find(obj.spike_subset(presets));
numNeurons = numel(whichNeurons);
binnedNeurons = cell(1, numNeurons);
try
    for n = 1:numNeurons
        neuronNo = whichNeurons(n);
        binnedNeurons{n} = obj.bin_neuron(neuronNo, 'preset', presets);
    end
catch
    binnedNeurons = []; 
end