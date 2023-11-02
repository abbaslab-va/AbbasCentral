function binnedTrials = bin_neuron(obj, event, neuron, varargin)

% OUTPUT:
%     binnedTrials - an E x T binary matrix of spike times for a neuron, 
%     where E is the number of events and T is the number of bins
% INPUT:
%     event -  an event character vector found in the config.ini file
%     neuron - number to index a neuron as organized in the spikes field
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1

validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validEvent = @(x) isempty(x) || ischar(x) || isstring(x);
validPreset = @(x) isa(x, 'PresetManager');

p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'bpod');
addParameter(p, 'withinState', [], validStates)
addParameter(p, 'priorToState', [], validStates)
addParameter(p, 'excludeEventsByState', [], validStates)
addParameter(p, 'priorToEvent', [], validEvent)
addParameter(p, 'preset', [], validPreset)
parse(p, event, neuron, varargin{:});

if isempty(p.Results.preset)
    a = p.Results;
else
    a = p.Results.preset;
end
baud = obj.info.baud;

if a.bpod
    timestamps = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'trials', a.trials, 'offset', a.offset, ...
        'priorToEvent', a.priorToEvent, 'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState);
else
    timestamps = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'trials', a.trials, 'offset', a.offset);
end

try
    adjustedEdges = (a.edges * baud) + timestamps';
    edgeCells = num2cell(adjustedEdges, 2);
    binnedTrials = cellfun(@(x) histcounts(obj.spikes(a.neuron).times, 'BinEdges', x(1):baud/1000*a.binWidth:x(2)),...
        edgeCells, 'uni', 0);
    binnedTrials = cat(1, binnedTrials{:});
    if isfield(obj.info, 'noisyPeriods')
        binnedTrials=obj.remove_noisy_periods(binnedTrials,a.event,'trialType', a.trialType, ...
        'outcome', a.outcome, 'offset', a.offset,'binWidth',a.binWidth,'edges',a.edges);
    end
catch
    binnedTrials = []; 
end