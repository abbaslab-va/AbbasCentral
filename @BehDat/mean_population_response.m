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
    validIndex = @(x) isempty(x) || (isvector(x) && numel(x) <= numel(obj.spikes));
    validWindow = @(x) isempty(x) || all(size(x) == [1, 2]);
    p = parse_BehDat('event', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'panel', 'bpod');
    addParameter(p, 'withinState', [], validStates)
    addParameter(p, 'priorToState', [], validStates)
    addParameter(p, 'excludeEventsByState', [], validStates)
    addParameter(p, 'priorToEvent', [], validEvent)
    addParameter(p, 'subset', [], validIndex)
    addParameter(p, 'sortBy', [], validWindow)
    parse(p, event, varargin{:});
    a = p.Results;

    zMean = obj.z_score(a.event, 'eWindow', a.edges, 'binWidth', a.binWidth, ...
        'trialType', a.trialType, 'outcome', a.outcome, 'eventTrials', a.trials, ...
        'offset', a.offset, 'bpod', a.bpod);
    if ~isempty(a.subset)
        zMean = zMean(a.subset, :);
    end
    if ~isempty(a.sortBy)
        msBins = a.edges * 1000 / a.binWidth;
        leftEdge = floor((a.sortBy(1) - msBins(1)) * a.binWidth) + 1;
        rightEdge = ceil((a.sortBy(2) - msBins(1)) * a.binWidth) - 1;
        valsToSort = mean(zMean(:, leftEdge:rightEdge), 2);
        [~, sortedIdx] = sort(valsToSort, 'descend');
        zMean = zMean(sortedIdx, :);
    end
    figTitle = strcat(obj.info.name, " ", a.event);
    h = plot_pop_response(zMean, a, figTitle);
end

function h = plot_pop_response(meanMat, params, figTitle)

    if isempty(params.panel)
        fontWeight = 24;
        title(figTitle)
        figure
    else
        fontWeight = 16;
        figH = figure('Visible', 'off');
    end
    h = heatmap(meanMat, 'GridVisible', 'off');
    colormap('parula')
    colorbar
    xlabel('Time From Event (sec)')
    ylabel('Neuron')
    timeLabels = cellfun(@(x) num2str(x), num2cell(params.edges(1):.5:params.edges(2)), 'uni', 0);
    leftEdge = params.edges(1)*1000/params.binWidth;
    rightEdge = params.edges(2)*1000/params.binWidth;
    stepSize = .5*1000/params.binWidth;
    timeTix = (leftEdge:stepSize:rightEdge) - leftEdge;
    timeTix(1) = 1;
    % xticks(timeTix)
    % xticklabels(timeLabels)
    % yticks([1 numel(h.YData)])
    % set(gca,'FontSize', fontWeight, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 1.5);
    xLabels = cell(size(meanMat, 2), 1);
    [xLabels{:}] = deal("");
    [xLabels{timeTix}] = timeLabels{:};
    numNeurons = size(meanMat, 1);
    neuronNumLabels = {num2str(1), num2str(numNeurons)};
    yLabels = cell(numNeurons, 1);
    [yLabels{:}] = deal("");
    [yLabels{[1, numNeurons], 1}] = neuronNumLabels{:};
    set(gca,'FontSize', fontWeight, 'FontName', 'Arial', 'XDisplayLabels', xLabels, 'YDisplayLabels', yLabels);
    if ~isempty(params.panel)
        copyobj(figH.Children, params.panel)
        close(figH)
    end
end
