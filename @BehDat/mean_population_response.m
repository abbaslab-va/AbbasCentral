function h = mean_population_response(obj, varargin)
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
    
    validWindow = @(x) isempty(x) || all(size(x) == [1, 2]);
    presets = PresetManager(varargin{:});
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'sortBy', [], validWindow)
    parse(p, varargin{:});
    sortBy = p.Results.sortBy;

    zMean = obj.z_score('preset', presets, 'eWindow', presets.edges, 'binWidth', presets.binWidth, ...
        'trialType', presets.trialType, 'outcome', presets.outcome, 'eventTrials', presets.trials, ...
        'offset', presets.offset, 'bpod', presets.bpod);
    if ~isempty(presets.subset)
        zMean = zMean(presets.subset, :);
    end
    if ~isempty(sortBy)
        msBins = presets.edges * 1000 / presets.binWidth;
        leftEdge = floor((sortBy(1) - msBins(1)) * presets.binWidth) + 1;
        rightEdge = ceil((sortBy(2) - msBins(1)) * presets.binWidth) - 1;
        valsToSort = mean(zMean(:, leftEdge:rightEdge), 2);
        [~, sortedIdx] = sort(valsToSort, 'descend');
        zMean = zMean(sortedIdx, :);
    end
    figTitle = strcat(obj.info.name, " ", presets.event);
    h = plot_pop_response(zMean, presets, figTitle);
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
    timeLabels = cellfun(@(x) num2str(x), num2cell((params.edges(1):.5:params.edges(2)) + params.offset), 'uni', 0);
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
