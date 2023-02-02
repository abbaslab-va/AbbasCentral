function binnedTrials = bin_neuron(obj, event, edges, neuron, binSize)


% INPUT:
%     event - string of an event defined in the config file
%     edges - 1x2 vector distance from event on either side in seconds
%     neuron - number to index a neuron as organized in the spikes field
%     binSize - an optional parameter to specify the bin width, in ms. default value is 1

if ~exist('binSize', 'var')
    binSize = 1;
end
baud = obj.info.baud;
timestamps = obj.find_event(event);
eventTrials = discretize(timestamps, [obj.timestamps.trialStart obj.info.samples]);
edges = (edges * baud) + timestamps';
edgeCells = num2cell(edges, 2);
spikeCells = obj.spikes(neuron).trialized(eventTrials)';
binnedTrials = cellfun(@(x, y) histcounts(x, 'BinEdges', y(1):baud/1000*binSize:y(2)),...
    spikeCells, edgeCells, 'uni', 0);
binnedTrials = cat(1, binnedTrials{:});