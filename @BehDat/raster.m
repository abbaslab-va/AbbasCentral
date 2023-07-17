function h = raster(obj, event, neuron, varargin)

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
    
    % bin spikes in 1 ms bins
    spikeMat = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binWidth', a.binWidth, 'trials', a.trials, ...
        'outcome', a.outcome, 'trialType', a.trialType, 'offset', a.offset, 'bpod', a.bpod, 'withinState', a.withinState));
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
        h = figure;
        plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
        label_raster(obj, h, a);
    end
end

function label_raster(sessObj, figH, params)
    title({sessObj.info.name, ['Neuron ' num2str(params.neuron)]})
    xlabel('Time From Event (sec)')
    ylabel('Events/Trials')
    timeLabels = cellfun(@(x) num2str(x), num2cell(params.edges(1):.5:params.edges(2)), 'uni', 0);
    leftEdge = params.edges(1)*1000/params.binWidth;
    rightEdge = params.edges(2)*1000/params.binWidth;
    stepSize = .5*1000/params.binWidth;
    timeTix = (leftEdge:stepSize:rightEdge) - leftEdge;
    xticks(timeTix)
    xticklabels(timeLabels)
    yticks([1 figH.Children.YLim(2) - 1])
    set(gca,'FontSize', 24, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 1.5);
end