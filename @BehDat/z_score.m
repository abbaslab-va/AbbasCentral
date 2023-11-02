function [zMean, zCells, trialNum] = z_score(obj, event, varargin)

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


% Parse inputs
validVectorSize = @(x) all(size(x) == [1, 2]);
validTrials = @(x) isempty(x) || isvector(x);
validPreset = @(x) isa(x, 'PresetManager');

p = parse_BehDat('event', 'trialType', 'outcome', 'offset', 'bpod');
addParameter(p, 'baseline', 'Trial Start', @ischar);
addParameter(p, 'bWindow', [-1 0], validVectorSize);
addParameter(p, 'eWindow', [-1 1], validVectorSize);
addParameter(p, 'binWidth', 20, @isscalar);
addParameter(p, 'baseTrials', [], validTrials)
addParameter(p, 'eventTrials', [], validTrials);
addParameter(p, 'preset', [], validPreset)

parse(p, event, varargin{:});
if isempty(p.Results.preset)
    a = p.Results;
else
    a = p.Results.preset;
end
baseline = p.Results.baseline;
bWindow = p.Results.bWindow;
eWindow = p.Results.eWindow;
baseTrials = a.baseTrials;
eventTrials = a.eventTrials;

baseTimes = obj.find_event(baseline, 'trialType', a.trialType, 'trials', baseTrials, ...
    'outcome', a.outcome, 'offset', a.offset);
if a.bpod
    eventTimes = obj.find_bpod_event(event, 'trialType', a.trialType, 'trials', eventTrials, ...
    'outcome', a.outcome, 'offset', a.offset);
else
    eventTimes = obj.find_event(event, 'trialType', a.trialType, 'trials', eventTrials, ...
    'outcome', a.outcome, 'offset', a.offset);
end
% Bin matrices of spikes for each baseline timestamp
baseEdges = num2cell((bWindow .* obj.info.baud) + baseTimes', 2);
baseCells = cellfun(@(x) obj.bin_spikes(x, a.binWidth), baseEdges, 'uni', 0);

% Calculate baseline statistics across all baseline timestamps
baseNeurons = cat(2, baseCells{:});
baseMean = mean(baseNeurons, 2);
baseSTD = std(baseNeurons, 0, 2);

% Z-score binned spikes around each event timestamp against baseline FR
eventEdges = num2cell((eWindow .* obj.info.baud) + eventTimes', 2);
eventCells = cellfun(@(x) obj.bin_spikes(x, a.binWidth), eventEdges, 'uni', 0);
zCells = cellfun(@(x) (x - baseMean)./baseSTD, eventCells, 'uni', 0);

% Find trial number for each event timestamp
trialNum = discretize(eventTimes, [baseTimes obj.info.samples]);
% Concatenate cells into 3d matrix, mean across trials, smooth and output
zAll = cat(3, zCells{:});
zMean = mean(zAll, 3);
zMean = smoothdata(zMean, 2, 'gaussian', floor(100/a.binWidth));
