function [zMean, zCells, trialNum] = z_score(obj, baseline, bWindow, event, eWindow, binWidth)

baseTimes = obj.find_event(baseline);
eventTimes = obj.find_event(event);
numBaseTS = numel(baseTimes);
numEventTS = numel(eventTimes);
baseCells = cell(1, numBaseTS);
zCells = cell(1, numEventTS);
%Bin matrices of spikes for each baseline timestamp
for b = 1:numBaseTS
    baseEdges = bWindow .* obj.info.baud + baseTimes(b);
    baselineTrial = obj.bin_spikes(baseEdges, binWidth);
    baseCells{b}= baselineTrial;
end
% Calculate baseline statistics across all baseline timestamps
baseNeurons = cat(2, baseCells{:});
baseMean = mean(baseNeurons, 2);
baseSTD = std(baseNeurons, 0, 2);
% Z-score binned spikes around each event timestamp against baseline FR
for e = 1:numEventTS
    eventEdges = eWindow .* obj.info.baud + eventTimes(e);
    eventTrial = obj.bin_spikes(eventEdges, binWidth);
    trialZ = (eventTrial - baseMean)./baseSTD;
    zCells{e} = trialZ;
end
trialNum = discretize(eventTimes, [baseTimes obj.info.samples]);
%Concatenate cells into 3d matrix, mean across trials, smooth and output
zAll = cat(3, zCells{:});
zMean = mean(zAll, 3);
zMean = smoothdata(zMean, 2, 'gaussian', 5);
