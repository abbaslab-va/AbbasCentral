function raster(obj, event, neuron, varargin)

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

p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'offset', 'panel', 'bpod');
parse(p, event, neuron, varargin{:});

a = p.Results;

% bin spikes in 1 ms bins
spikeMat = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binWidth', a.binWidth, ...
    'outcome', a.outcome, 'trialType', a.trialType, 'offset', a.offset, 'bpod', a.bpod));
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