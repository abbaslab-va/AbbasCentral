function spikeMat = continuous_population_activity(obj, varargin)

% This method aims to plot activity of a collection of neurons, z-scored to
% within its own window, outside of any trial confinements.

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
validVectorSize = @(x) all(size(x) == [1, 2]);
addParameter(p, 'sortBy', [], validVectorSize)
parse(p, varargin{:});
extraArgs = p.Results;
whichNeurons = find(obj.spike_subset(presets));
numNeurons = numel(whichNeurons);
numSamples = abs(diff(presets.edges) / obj.info.baud * 1000 / presets.binWidth);
spikeMat = zeros(numNeurons, numSamples);

for i = 1:numNeurons
    spikeMat(i, :) = obj.bin_spikes(presets.edges, presets.binWidth, whichNeurons(i));
end

if presets.normalized
    baseMean = mean(spikeMat, 2);
    baseSTD = std(spikeMat, 0, 2);
    
    spikeMat = (spikeMat - baseMean)./baseSTD;
end

if ~isempty(extraArgs.sortBy)
    meanSortVals = mean(spikeMat(:, extraArgs.sortBy), 2);
    [~, sortedIdx] = sort(meanSortVals, 'ascend');
    spikeMat = spikeMat(sortedIdx, :);
end