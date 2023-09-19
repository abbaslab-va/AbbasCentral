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
    validEvent = @(x) isempty(x) || ischar(x) || isstring(x);
    p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'panel', 'bpod');
    addParameter(p, 'withinState', [], validStates)
    addParameter(p, 'priorToState', [], validStates)
    addParameter(p, 'excludeEventsByState', [], validStates)
    addParameter(p, 'priorToEvent', [], validEvent)
    parse(p, event, neuron, varargin{:});
    
    a = p.Results;
    
    % bin spikes in 1 ms bins. If no trialType or outcome param, return all
    % as one matrix
    if (isempty(a.trialType) && isempty(a.outcome)) || (~iscell(a.trialType) && ~iscell(a.outcome))
        spikeMat = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binWidth', a.binWidth, 'trials', a.trials, ...
            'outcome', a.outcome, 'trialType', a.trialType, 'offset', a.offset, 'bpod', a.bpod, 'priorToEvent', a.priorToEvent, ...
            'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState));
    else
        % parse through all inputted trialTypes and outcomes to produce a
        % stacked raster plot of all combos
        if ~iscell(a.trialType)
            a.trialType = num2cell(a.trialType, [1 2]);
        end
        if ~iscell(a.outcome)
            a.outcome = num2cell(a.outcome, [1 2]);
        end
        spikeMat = cell(numel(a.trialType) * numel(a.outcome), 1);
        labelY = spikeMat;
        lineY = zeros(numel(a.trialType) * numel(a.outcome), 1);
        tickY = lineY;
        ctr = 0;
        totalSz = 0;
        for tt = 1:numel(a.trialType)
            for o = 1:numel(a.outcome)
                ctr = ctr + 1;
                currentTT = a.trialType{tt};
                currentOutcome = a.outcome{o};
                spikeMat{ctr} = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binWidth', a.binWidth, 'trials', a.trials, ...
                'trialType', currentTT, 'outcome', currentOutcome, 'offset', a.offset, 'bpod', a.bpod, 'priorToEvent', a.priorToEvent, ...
                'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState));
                numRows = size(spikeMat{ctr}, 1);
                lineY(ctr) = numRows + totalSz;
                totalSz = lineY(ctr);
                tickY(ctr) = totalSz - .5 * numRows;
                labelY{ctr} = strcat(currentTT, ", ", currentOutcome);
            end
        end
        spikeMat = cat(1, spikeMat{:});
    end

    % Remove the last value so it doesn't plot line below the raster plot
    if ~exist('lineY', 'var')
        lineY = -1;
        tickY = [0, size(spikeMat, 1)];
        labelY = {};
    else
        lineY(end) = [];
    end
    

    % this function included in packages directory of Abbas-WM
    % Jeffrey Chiou (2023). Flexible and Fast Spike Raster Plotting 
    % (https://www.mathworks.com/matlabcentral/fileexchange/45671-flexible-and-fast-spike-raster-plotting), 
    % MATLAB Central File Exchange. Retrieved February 2, 2023. 
    
    
    if ~isempty(a.panel)
        h = figure('Visible', 'off');
        plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
        if ~isempty(lineY)
            yline(lineY + .5, 'LineWidth', 1.5)
            yticks(tickY + .5)
            yticklabels(labelY)
            ytickangle(45)
        end
        copyobj(h.Children, a.panel)
        close(h)
    else
        h = figure;
        plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
        if ~isempty(lineY)
            yline(lineY + .5, 'LineWidth', 1.5)
        end
        label_raster(obj, h, a);
        if ~isempty(lineY)
            yticks(tickY + .5)
            yticklabels(labelY)
            ytickangle(45)
        end
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