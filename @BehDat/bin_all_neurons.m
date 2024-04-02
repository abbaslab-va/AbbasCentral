function binnedNeurons = bin_all_neurons(obj, varargin)

% OUTPUT:
%     meanFR - NxT matrix of averaged firing rates, where N is the number of
%     neurons and T is the number of bins
%     frCells - a 1xE cell array where E is the number of events. Each cell
%     contains an NxT matrix of firing rates for that trial.
%     trialNum - an index of the bpod trial the event occurred in
% INPUT:
%     event -  an event character vector found in the config.ini file
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1

presets = PresetManager(varargin{:});
baud = obj.info.baud;
binStep = baud/1000*presets.binWidth;
timestamps = obj.find_event('preset', presets, 'trialized', false);

binnedNeurons = cell(1, numel(obj.spikes));
try
    adjustedEdges = (presets.edges * baud) + timestamps';
    edgeCells = num2cell(adjustedEdges, 2);
    for neuron = 1:numel(obj.spikes)
        binnedN = cellfun(@(x) histcounts(obj.spikes(neuron).times, 'BinEdges', x(1):binStep:x(2)),...
            edgeCells, 'uni', 0);
        binnedNeurons{neuron} = cat(1, binnedN{:});
    end
catch
    binnedNeurons = []; 
end