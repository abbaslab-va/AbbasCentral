function noiseRemoved = remove_noisy_periods(obj, rawData, event, varargin)

% This function will return a matrix where time points corresponding to
% periods that have been removed prior to kilosorting will be marked with
% NaN. 

% OUTPUT:
%     noiseRemoved - an NxT matrix with the same dimensions as rawData,
%     with rows corresponding to neurons or trials, and T corresponding to
%     time points in the chosen bin width.
% INPUT:
%     rawData - the output of a function like bin_neuron, ppc, cwt_power,
%     etc. that return a matrix of trialized binned data.
%     event - an event string listed in config.ini
% optional name/value pairs:
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'binWidth' - the size of the bins in ms
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini

validPreset = @(x) isa(x, 'PresetManager');

p = parse_BehDat('event', 'edges', 'offset', 'binWidth', 'outcome', 'trialType', 'trials');
addParameter(p, 'preset', [], validPreset)

parse(p, event, varargin{:});
if isempty(p.Results.preset)
    a = p.Results;
else
    a = p.Results.preset;
end
offset = round(a.offset * obj.info.baud);
baud = obj.info.baud;
noiseRemoved = rawData;

eventTimes = obj.find_event(a.event, 'offset', offset, 'outcome', a.outcome, 'trialType', a.trialType, 'trials', a.trials);
eventEdges = num2cell((a.edges * baud) + eventTimes', 2);
eventBins = cellfun(@(x) x(1):baud*a.binWidth/1000:x(2), eventEdges, 'uni', 0);

noisyBins = cellfun(@(x) discretize(obj.info.noisyPeriods, x), eventBins, 'uni', 0);
noisyBins = cellfun(@(x) unique(x(~isnan(x))), noisyBins, 'uni', 0);

for t = 1:numel(noisyBins)
    noiseRemoved(t, noisyBins{t}) = nan;
end
