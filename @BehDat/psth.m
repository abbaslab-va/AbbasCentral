function smoothSpikes=psth(obj, event, neuron, varargin)
% OUTPUT:
%     smoothSpikes- a 1xT vector of smoothed spike times
% INPUT:
%     event - a string of a state named in the config file
%     neuron - index of neuron from spike field of object
% 
% optional name/value pairs:
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'binWidth' - a number that defines the bin size in ms
%     'trialType' - a trial type found in config.ini
%     'outcome' - an outcome character array found in config.ini
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'panel' - an optional handle to a panel (in the AbbasCentral app)
%     'bpod' - a boolean that determines whether to use bpod or native timestamps

validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'panel', 'bpod');
addParameter(p, 'withinState', [], validStates)
parse(p, event, neuron, varargin{:});

a = p.Results;

spikeMat = obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'offset', a.offset, 'binWidth', a.binWidth, ...
    'outcome', a.outcome, 'trialType', a.trialType, 'trials', a.trials, 'bpod', a.bpod, 'withinState', a.withinState);

meanSpikes = mean(spikeMat, 1);
smoothSpikes = smoothdata(meanSpikes, 'Gaussian', 50)*(1000/a.binWidth);
if ~isempty(a.panel)
    h = figure('Visible', 'off');
    plot(smoothSpikes)    
    copyobj(h.Children, a.panel)
    close(h)
else
    figure
    plot(smoothSpikes)   
end
     

% set(gcf, 'Position', get(0, 'Screensize'));