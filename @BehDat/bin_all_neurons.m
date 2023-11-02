function binnedNeurons = bin_all_neurons(obj, event, varargin)

% OUTPUT:
%     meanFR - NxT matrix of averaged firing rates, where N is the number of
%     neurons and T is the number of bins
%     frCells - a 1xE cell array where E is the number of events. Each cell
%     contains an NxT matrix of firing rates for that trial.
%     trialNum - an index of the bpod trial the event occurred in
% INPUT:
%     event -  an event character vector found in the config.ini file
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1


validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validPreset = @(x) isa(x, 'PresetManager');
p = parse_BehDat('event', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'bpod');
addParameter(p, 'withinState', [], validStates)
addParameter(p, 'priorToState', [], validStates)
addParameter(p, 'excludeEventsByState', [], validStates)
addParameter(p, 'priorToEvent', [], validEvent)
addParameter(p, 'preset', [], validPreset)
parse(p, event, varargin{:});

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

binnedNeurons = cell(1, numel(obj.spikes));
try
    adjustedEdges = (a.edges * baud) + timestamps';
    edgeCells = num2cell(adjustedEdges, 2);
    for neuron = 1:numel(obj.spikes)
        binnedN = cellfun(@(x) histcounts(obj.spikes(neuron).times, 'BinEdges', x(1):baud/1000*a.binWidth:x(2)),...
            edgeCells, 'uni', 0);
        binnedNeurons{neuron} = cat(1, binnedN{:});
        if isfield(obj.info, 'noisyPeriods')
            frCells=obj.remove_noisy_periods(frCells,a.event,'trialType', a.trialType, ...
            'outcome', a.outcome, 'offset', a.offset,'binWidth',a.binWidth,'edges',a.edges);
        end
    end
catch
    binnedNeurons = []; 
end