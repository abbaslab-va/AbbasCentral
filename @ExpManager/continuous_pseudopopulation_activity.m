function [spikeMat, sortedIdx] = continuous_pseudopopulation_activity(obj, varargin);

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
validVectorSize = @(x) all(size(x) == [1, 2]) || isempty(x);
addParameter(p, 'sortBy', [], validVectorSize)
addParameter(p, 'orderBy', [], @isvector)
parse(p, varargin{:});
extraArgs = p.Results;
goodSessions = arrayfun(@(x) strcmp(presets.condition, x.info.condition), obj.sessions);

activityBySession = arrayfun(@(x) x.continuous_population_activity('preset', presets, 'sortBy', []), obj.sessions(goodSessions), 'uni', 0);

spikeMat = cellfun(@(x) cat(1, x{:}), activityBySession, 'uni', 0);
spikeMat = cat(1, spikeMat{:});

if presets.normalized
    baseMean = mean(spikeMat, 2);
    baseSTD = std(spikeMat, 0, 2);
    
    spikeMat = (spikeMat - baseMean)./baseSTD;
end

if ~isempty(extraArgs.sortBy)
    sortBounds = extraArgs.sortBy(1):extraArgs.sortBy(2);
    meanSortVals = mean(spikeMat(:, sortBounds), 2);
    [~, sortedIdx] = sort(meanSortVals, 'ascend');
    spikeMat = spikeMat(sortedIdx, :);
end

if ~isempty(extraArgs.orderBy)
    spikeMat = spikeMat(extraArgs.orderBy, :);
end