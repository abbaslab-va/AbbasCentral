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
    validEvent = @(x) isempty(x) || ischar(x) || isstring(x);
    p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'panel', 'bpod');
    addParameter(p, 'withinState', [], validStates)
    addParameter(p, 'priorToState', [], validStates)
    addParameter(p, 'excludeEventsByState', [], validStates)
    addParameter(p, 'priorToEvent', [], validEvent)
    parse(p, event, neuron, varargin{:});
    
    a = p.Results;
    
    spikeMat = obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'offset', a.offset, 'binWidth', a.binWidth, ...
        'outcome', a.outcome, 'trialType', a.trialType, 'trials', a.trials, 'bpod', a.bpod, 'priorToEvent', a.priorToEvent, ...
            'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState);
    
    meanSpikes = mean(spikeMat, 1);
    smoothSpikes = smoothdata(meanSpikes, 'Gaussian', 50)*(1000/a.binWidth);
    if ~isempty(a.panel)
        h = figure('Visible', 'off');
        plot(smoothSpikes)    
        copyobj(h.Children, a.panel)
        close(h)
    else
        h = figure;
        plot(smoothSpikes)
        label_psth(obj, h, a);
    end
end

function label_psth(sessObj, figH, params)
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