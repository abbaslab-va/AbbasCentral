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
%     'binSize' - an optional parameter to specify the bin width, in ms. default value is 1

defaultEdges = [-2 2];          % seconds
defaultOutcome = [];            % all outcomes
defaultTrialType = [];          % all TrialTypes
defaultBinSize = 1;             % ms
defaultOffset = 0;              % offset from event in seconds

validVectorSize = @(x) all(size(x) == [1, 2]);
validField = @(x) ischar(x) || isempty(x);
p = inputParser;
addRequired(p, 'event', @ischar);
addRequired(p, 'neuron', @isnumeric);
addParameter(p, 'edges', defaultEdges, validVectorSize);
addParameter(p, 'binSize', defaultBinSize, @isnumeric);
addParameter(p, 'trialType', defaultTrialType, validField);
addParameter(p, 'outcome', defaultOutcome, validField);
addParameter(p, 'offset', defaultOffset, @isnumeric);

a = p.Results;
event = a.event;
neuron = a.neuron;
edges = a.edges;
binSize = a.binSize;
trialTypeField = a.trialType;
outcomeField = a.outcome;
offset = a.offset;

baud = obj.info.baud;

timestamps = obj.find_event(event, 'trialType', trialType, 'outcome', outcome, 'offset', offset);

eventTrials = discretize(timestamps, [obj.timestamps.trialStart obj.info.samples]);
edges = (edges * baud) + timestamps';
edgeCells = num2cell(edges, 2);
spikeCells = obj.spikes(neuron).trialized(eventTrials)';
binnedTrials = cellfun(@(x, y) histcounts(x, 'BinEdges', y(1):baud/1000*binSize:y(2)),...
    spikeCells, edgeCells, 'uni', 0);
binnedTrials = cat(1, binnedTrials{:});

if exist('trialTypes', 'var')
    eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
    trials = find(ismember(eventTrialTypes, trialTypes));
    numTrials = size(binnedTrials, 1);
    trials = trials(trials <= numTrials);
    binnedTrials = binnedTrials(trials, :);
end