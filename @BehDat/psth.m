function psth(obj, event, neuron, varargin)

% INPUT:
%     event - a string of a state named in the config file
%     edges - 1x2 vector distance from event on either side in seconds
%     neuron - index of neuron from spike field of object
%     panel - an optional handle to a panel (in the AbbasCentral app)
%     trialTypes - an optional argument specifying the trial type to bin
defaultEdges = [-2 2];          % seconds
defaultOutcome = [];            % all outcomes
defaultTrialType = [];          % all TrialTypes
defaultBinSize = 1;             % ms
defaultOffset = 0;              % offset from event in seconds
defaultPanel = [];
defaultBpod = false;

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
addParameter(p, 'panel', defaultPanel)
addParameter(p, 'bpod', defaultBpod, @islogical)
parse(p, event, neuron, varargin{:});

a = p.Results;

spikeMat = obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binSize', a.binSize, ...
    'outcome', a.outcome, 'trialType', a.trialType, 'offset', a.offset, 'bpod', a.bpod);

meanSpikes = mean(spikeMat, 1);
smoothSpikes = smoothdata(meanSpikes, 'Gaussian', 50);
if ~isempty(a.panel)
    h = figure('Visible', 'off');
    plot(smoothSpikes * 2000)    
    copyobj(h.Children, a.panel)
    close(h)
else
    figure
    plot(smoothSpikes * 2000)   
end
     

% set(gcf, 'Position', get(0, 'Screensize'));