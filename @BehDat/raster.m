function raster(obj, event, edges, neuron, panel, trialTypes)

% INPUT:
%     event - a string of a state named in the config file
%     edges - 1x2 vector distance from event on either side in seconds
%     neuron - index of neuron from spike field of object

% bin spikes in 1 ms bins
spikeMat = boolean(obj.bin_neuron(event, edges, neuron, 1, trialTypes));
% this function included in packages directory of Abbas-WM
% Jeffrey Chiou (2023). Flexible and Fast Spike Raster Plotting 
% (https://www.mathworks.com/matlabcentral/fileexchange/45671-flexible-and-fast-spike-raster-plotting), 
% MATLAB Central File Exchange. Retrieved February 2, 2023. 

if exist('panel', 'var')
    h = figure('Visible', 'off');
    plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
    copyobj(h.Children, panel)
    close(h)
else
    plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
end