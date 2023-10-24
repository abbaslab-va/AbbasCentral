function h = mean_population_response(obj, event, varargin)
    % OUTPUT:
    %     h - figure handle to a surface plot
    % INPUT:
    %     event - a string of a state named in the config file
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
    p = parse_BehDat('event', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'panel', 'bpod');
    addParameter(p, 'withinState', [], validStates)
    addParameter(p, 'priorToState', [], validStates)
    addParameter(p, 'excludeEventsByState', [], validStates)
    addParameter(p, 'priorToEvent', [], validEvent)
    parse(p, event, varargin{:});
    a = p.Results;

    zMean = obj.z_score(a.event, 'eWindow', a.edges, 'binWidth', a.binWidth, ...
        'trialType', a.trialType, 'outcome', a.outcome, 'eventTrials', a.trials, ...
        'offset', a.offset, 'bpod', a.bpod);
    figTitle = strcat(obj.info.name, " ", a.event);
    h = plot_pop_response(zMean, a, figTitle);
end

function h = plot_pop_response(meanMat, params, figTitle)
    figure
    h = surf(meanMat);
    view(2)
    colormap('parula')
    set(h, 'edgecolor', 'none');
    colorbar

    if params.panel
        fontWeight = 16;
    else
        fontWeight = 24;
        title(figTitle)
    end
    xlabel('Time From Event (sec)')
    ylabel('Neuron')
    timeLabels = cellfun(@(x) num2str(x), num2cell(params.edges(1):.5:params.edges(2)), 'uni', 0);
    leftEdge = params.edges(1)*1000/params.binWidth;
    rightEdge = params.edges(2)*1000/params.binWidth;
    stepSize = .5*1000/params.binWidth;
    timeTix = (leftEdge:stepSize:rightEdge) - leftEdge;
    xticks(timeTix)
    xticklabels(timeLabels)
    yticks([1 numel(h.YData)])
    set(gca,'FontSize', fontWeight, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 1.5);
end
