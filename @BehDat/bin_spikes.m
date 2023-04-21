function binnedSpikes = bin_spikes(obj, eventEdges, binSize, neuronNo)

% OUTPUT:
%     binnedSpikes - an N x T binary matrix of binned spikes around an event, 
%     where N is the number of neurons in the session and T is the number of bins.
% INPUT:
%     eventEdges - a 1x2 vector specifying the edges to bin between
%     binSize - the size of the bins in ms

stepSize = floor(obj.info.baud/1000*binSize);
binEdges = eventEdges(1):stepSize:eventEdges(2);
numNeurons = numel(obj.spikes);

if ~exist('neuronNo','var')
    binnedSpikes = zeros(numNeurons, numel(binEdges)-1);
    for i = 1:numNeurons
        binnedSpikes(i, :) = histcounts(obj.spikes(i).times, 'BinEdges', binEdges);
    end
elseif numel(neuronNo)>1
    for i=1:numel(neuronNo)
        binnedSpikes(i, :)=histcounts(obj.spikes(neuronNo(i)).times, 'BinEdges', binEdges);
    end
else 
    binnedSpikes=histcounts(obj.spikes(neuronNo).times, 'BinEdges', binEdges); 
end 
