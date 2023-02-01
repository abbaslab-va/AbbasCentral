function binnedSpikes = bin_spikes(obj, eventEdges, binSize)
    stepSize = floor(obj.baud/1000*binSize);
    binEdges = eventEdges(1):stepSize:eventEdges(2);
    numNeurons = numel(obj.spikes);
    binnedSpikes = zeros(numNeurons, numel(binEdges)-1);
    for i = 1:numNeurons
        binnedSpikes(i, :) = histcounts(obj.spikes(i).times, 'BinEdges', binEdges);
    end
end