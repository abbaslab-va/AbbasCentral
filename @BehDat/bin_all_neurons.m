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
p = parse_BehDat('event', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'bpod');
addParameter(p, 'withinState', [], validStates)
addParameter(p, 'priorToState', [], validStates)
addParameter(p, 'excludeEventsByState', [], validStates)
addParameter(p, 'priorToEvent', [], validEvent)
parse(p, event, varargin{:});

a = p.Results;
event = a.event;
edges = a.edges;
binWidth = a.binWidth;
trialTypeField = a.trialType;
outcomeField = a.outcome;
offset = a.offset;
trials = a.trials;
useBpod = a.bpod;

baud = obj.info.baud;
if useBpod
    timestamps = obj.find_bpod_event(event, 'trialType', trialTypeField, 'outcome', outcomeField, 'trials', trials, 'offset', offset, ...
        'priorToEvent', a.priorToEvent, 'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState);
else
    timestamps = obj.find_event(event, 'trialType', trialTypeField, 'outcome', outcomeField, 'trials', trials, 'offset', offset);
end

binnedNeurons = cell(1, numel(obj.spikes));
try
    adjustedEdges = (edges * baud) + timestamps';
    edgeCells = num2cell(adjustedEdges, 2);
    for neuron = 1:numel(obj.spikes)
        binnedN = cellfun(@(x) histcounts(obj.spikes(neuron).times, 'BinEdges', x(1):baud/1000*binWidth:x(2)),...
            edgeCells, 'uni', 0);
        binnedNeurons{neuron} = cat(1, binnedN{:});
        if isfield(obj.info, 'noisyPeriods')
            frCells=obj.remove_noisy_periods(frCells,event,'trialType', trialTypeField, ...
            'outcome', outcomeField, 'offset', offset,'binWidth',binWidth,'edges',edges);
        end
    end
catch
    binnedNeurons = []; 
end