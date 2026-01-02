function [zMean, zCells, trialNum] = z_score(obj, varargin)

% Returns smoothed Z-Scored firing rates centered around events
% 
% OUTPUT:
%     zMean - NxT matrix of z-scored firing rates, where N is the number of
%     neurons and T is the number of bins
%     zCells - a 1xE cell array where E is the number of events. Each cell
%     contains an NxT matrix of firing rates for that trial.
%     trialNum - an index of the bpod trial the event occurred in
% INPUT:
%     baseline - string, name of the event to use as baseline
%     bWindow - 1x2 vector, time window to use for baseline FR
%     event - string, name of the event to use as event
%     eWindow - 1x2 vector, time window to use for event FR
%     binWidth - scalar, width of the bins in milliseconds

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
% Parse inputs
validVectorSize = @(x) all(size(x) == [1, 2]);
validTrials = @(x) isempty(x) || isvector(x);

addParameter(p, 'baseline', '', @ischar);
addParameter(p, 'bWindow', [-1 0], validVectorSize);
addParameter(p, 'bpodBaseline', false, @islogical);
addParameter(p, 'eWindow', [-1 1], validVectorSize);
addParameter(p, 'baseTrials', [], validTrials)
addParameter(p, 'averaged', true, @islogical)


parse(p, varargin{:});
baseline = p.Results.baseline;
bWindow = p.Results.bWindow;
bpodBaseline = p.Results.bpodBaseline;
eWindow = p.Results.eWindow;
binWidth = presets.binWidth;
baseTrials = p.Results.baseTrials;
averaged = p.Results.averaged;

baseTimes = obj.find_event('event', baseline, 'trialType', presets.trialType, 'trials', baseTrials, ...
    'outcome', presets.outcome, 'offset', presets.offset, 'bpod', bpodBaseline);
eventTimes = obj.find_event(varargin{:}, 'trialized', false);

% % Bin matrices of spikes for each baseline timestamp
baseEdges = num2cell((bWindow .* obj.info.baud) + baseTimes', 2);
baseCells = cellfun(@(x) obj.bin_spikes(x, binWidth), baseEdges, 'uni', 0);


% Calculate baseline statistics across all baseline timestamps
baseNeurons = cat(2, baseCells{:});
baseMean = mean(baseNeurons, 2);
baseSTD = std(baseNeurons, 0, 2);

% Z-score binned spikes around each event timestamp against baseline FR
eventEdges = num2cell((eWindow .* obj.info.baud) + eventTimes', 2);
eventCells = cellfun(@(x) obj.bin_spikes(x, binWidth), eventEdges, 'uni', 0);
eventMean = cellfun(@(x) mean(x, 2, 'omitnan'), eventCells, 'uni', 0);
eventSTD = cellfun(@(x) std(x, 0, 2,  'omitnan'), eventCells, 'uni', 0);
if isempty(baseline)
    zCells = cellfun(@(x, y, z) (x - y)./z, eventCells, eventMean, eventSTD, 'uni', 0);
else
    zCells = cellfun(@(x) (x - baseMean)./baseSTD, eventCells, 'uni', 0);
end

% Find trial number for each event timestamp
trialNum = discretize(eventTimes, [baseTimes obj.info.samples]);
% Concatenate cells into 3d matrix, mean across trials, smooth and output
zAll = cat(3, zCells{:});
if averaged

end
zMean = mean(zAll, 3, 'omitnan');
zMean = smoothdata(zMean, 2, 'gaussian', floor(100/binWidth));
whichSpikes = obj.spike_subset(presets);
zMean = zMean(whichSpikes, :);