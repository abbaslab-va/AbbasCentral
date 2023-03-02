function binnedSpikes = bin_spikes(obj, eventEdges, binSize)

% OUTPUT:
%     binnedSpikes - an N x T binary matrix of binned spikes around an event, 
%     where N is the number of neurons in the session and T is the number of bins.
% INPUT:
%     eventEdges - a 1x2 vector specifying the edges to bin between
%     binSize - the size of the bins in ms

stepSize = floor(obj.info.baud/1000*binSize);
binEdges = eventEdges(1):stepSize:eventEdges(2);
numNeurons = numel(obj.spikes);
binnedSpikes = zeros(numNeurons, numel(binEdges)-1);
for i = 1:numNeurons
    binnedSpikes(i, :) = histcounts(obj.spikes(i).times, 'BinEdges', binEdges);
end


% rewrite to bin spikes around all events in trial