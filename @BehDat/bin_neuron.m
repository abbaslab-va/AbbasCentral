function binnedTrials = bin_neuron(obj, event, neuron, varargin)

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
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1

p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'offset', 'bpod')

parse(p, event, neuron, varargin{:});

a = p.Results;
event = a.event;
neuron = a.neuron;
edges = a.edges;
binWidth = a.binWidth;
trialTypeField = a.trialType;
outcomeField = a.outcome;
offset = a.offset;
useBpod = a.bpod;

baud = obj.info.baud;
if useBpod
    timestamps = obj.find_bpod_event(event, 'trialType', trialTypeField, 'outcome', outcomeField, 'offset', offset);
else
    timestamps = obj.find_event(event, 'trialType', trialTypeField, 'outcome', outcomeField, 'offset', offset);
end

try
    edges = (edges * baud) + timestamps';
    edgeCells = num2cell(edges, 2);
    binnedTrials = cellfun(@(x) histcounts(obj.spikes(neuron).times, 'BinEdges', x(1):baud/1000*binWidth:x(2)),...
        edgeCells, 'uni', 0);
    binnedTrials = cat(1, binnedTrials{:});
    binnedTrials=obj.remove_noisy_periods(binnedTrials,event,'trialType', trialTypeField, ...
        'outcome', outcomeField, 'offset', offset,'binWidth',binWidth,'edges',edges);
catch
    binnedTrials = [];

end