function binnedTrials = bin_neuron(obj, neuron, varargin)

% OUTPUT:
%     binnedTrials - an E x T binary matrix of spike times for a neuron, 
%     where E is the number of events and T is the number of bins
% INPUT:
%     event -  an event character vector found in the config.ini file
%     neuron - number to index a neuron as organized in the spikes field
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1

presets = PresetManager(varargin{:});


baud = obj.info.baud;

if presets.bpod
    timestamps = obj.find_bpod_event('preset', presets);
else
    timestamps = obj.find_event('preset', presets);
end

try
    adjustedEdges = (presets.edges * baud) + timestamps';
    edgeCells = num2cell(adjustedEdges, 2);
    binnedTrials = cellfun(@(x) histcounts(obj.spikes(neuron).times, 'BinEdges', x(1):baud/1000*presets.binWidth:x(2)),...
        edgeCells, 'uni', 0);
    binnedTrials = cat(1, binnedTrials{:});
    if isfield(obj.info, 'noisyPeriods')
        binnedTrials=obj.remove_noisy_periods(binnedTrials, presets.event, 'trialType', presets.trialType, ...
        'outcome', presets.outcome, 'offset', presets.offset,'binWidth', presets.binWidth, 'edges', presets.edges);
    end
catch
    binnedTrials = []; 
end