function raster(obj, event, neuron, varargin)

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
parse(p, event, neuron, varargin{:});

a = p.Results;

% bin spikes in 1 ms bins
spikeMat = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binSize', a.binSize, ...
    'outcome', a.outcome, 'trialType', a.trialType, 'offset', a.offset));
% this function included in packages directory of Abbas-WM
% Jeffrey Chiou (2023). Flexible and Fast Spike Raster Plotting 
% (https://www.mathworks.com/matlabcentral/fileexchange/45671-flexible-and-fast-spike-raster-plotting), 
% MATLAB Central File Exchange. Retrieved February 2, 2023. 


if ~isempty(a.panel)
    h = figure('Visible', 'off');
    plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
    copyobj(h.Children, a.panel)
    close(h)
else
    figure
    plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
end