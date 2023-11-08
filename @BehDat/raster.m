function h = raster(obj, neuron, varargin)

    % INPUT:
    %     neuron - index of neuron from spike field of object
    % 
    % optional name/value pairs:
    %     'event' - a string of a state named in the config file
    %     'edges' - 1x2 vector distance from event on either side in seconds
    %     'binWidth' - a number that defines the bin size in ms
    %     'trialType' - a trial type found in config.ini
    %     'outcome' - an outcome character array found in config.ini
    %     'offset' - a number that defines the offset from the alignment you wish to center around.
    %     'panel' - an optional handle to a panel (in the AbbasCentral app)
    %     'bpod' - a boolean that determines whether to use bpod or native timestamps
    

    presets = PresetManager(varargin{:});
    
    
    % bin spikes in 1 ms bins. If no trialType or outcome param, return all
    % as one matrix
    if (isempty(presets.trialType) && isempty(presets.outcome)) || (~iscell(presets.trialType) && ~iscell(presets.outcome))
        spikeMat = boolean(obj.bin_neuron(neuron, 'preset', presets));
    else
        % parse through all inputted trialTypes and outcomes to produce a
        % stacked raster plot of all combos
        if ~iscell(presets.trialType)
            presets.trialType = num2cell(presets.trialType, [1 2]);
        end
        if ~iscell(presets.outcome)
            presets.outcome = num2cell(presets.outcome, [1 2]);
        end
        numTT = numel(presets.trialType);
        numTT(numTT == 0) = 1;
        numOutcomes = numel(presets.outcome);
        numOutcomes(numOutcomes == 0) = 1;
        spikeMat = cell(numTT * numOutcomes, 1);
        labelY = spikeMat;
        lineY = zeros(numTT * numOutcomes, 1);
        tickY = [lineY; lineY];
        ctr = 0;
        totalSz = 0;
        for tt = 1:numTT
            if numel(presets.trialType) == 0
                currentTT = [];
                currentTTString = 'All';
            else
                currentTT = presets.trialType{tt};
                currentTTString = currentTT;
            end
            for o = 1:numOutcomes
                if numel(presets.outcome) == 0
                    currentOutcome = [];
                    currentOutcomeString = 'All';
                else
                    currentOutcome = presets.outcome{o};
                    currentOutcomeString = currentOutcome;
                end
                ctr = ctr + 1;
                spikeMat{ctr} = boolean(obj.bin_neuron(neuron, 'event', presets.event, 'edges', presets.edges, 'binWidth', presets.binWidth, 'trials', presets.trials, ...
                'trialType', currentTT, 'outcome', currentOutcome, 'offset', presets.offset, 'bpod', presets.bpod, 'priorToEvent', presets.priorToEvent, ...
                'priorToState', presets.priorToState, 'withinState', presets.withinState, 'excludeEventsByState', presets.excludeEventsByState));
                numRows = size(spikeMat{ctr}, 1);
                lineY(ctr) = numRows + totalSz;
                totalSz = lineY(ctr);
                tickY(ctr*2 - 1) = totalSz - .5 * numRows;
                tickY(ctr*2) = totalSz;
                labelY{ctr*2 - 1} = strcat(currentTTString, ", ", currentOutcomeString);
                labelY{ctr*2} = num2str(numRows);
            end
        end
        spikeMat = cat(1, spikeMat{:});
    end

    % Remove the last value so it doesn't plot line below the raster plot
    if ~exist('lineY', 'var')
        lineY = -1;
        tickY = [0, size(spikeMat, 1)];
        labelY = {};
    elseif ~isempty(lineY)
        lineY(end) = [];
    end
  
    
    if ~isempty(presets.panel)
        h = figure('Visible', 'off');
        plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
        % this function included in packages directory of Abbas-WM
        % Jeffrey Chiou (2023). Flexible and Fast Spike Raster Plotting 
        % (https://www.mathworks.com/matlabcentral/fileexchange/45671-flexible-and-fast-spike-raster-plotting), 
        % MATLAB Central File Exchange. Retrieved February 2, 2023. 
        label_raster(obj, neuron, h, presets, true);
        if ~isempty(lineY) && all(diff(tickY))
            yline(lineY + .5, 'LineWidth', 1.5, 'Color', 'k')
            yticks(tickY + .5)
            yticklabels(labelY)
            ytickangle(45)
        end
        set(gca, 'color', 'w')
        copyobj(h.Children, presets.panel)
        close(h)
    else
        h = figure;
        plotSpikeRaster(spikeMat, 'PlotType', 'vertline', 'VertSpikeHeight', .8);
        h = label_raster(obj, neuron, h, presets, false);
        if ~isempty(lineY)
            yline(lineY + .5, 'LineWidth', 1.5, 'Color', 'k')
            yticks(tickY + .5)
            yticklabels(labelY)
            ytickangle(45)
        end
        set(gca, 'color', 'w')
    end
end

function figH = label_raster(sessObj, neuron, figH, params, panel)
    if panel
        fontWeight = 16;
    else
        fontWeight = 24;
        title({sessObj.info.name, ['Neuron ' num2str(neuron)]})
    end
    xlabel('Time From Event (sec)', 'Color', 'k')
    ylabel('Events/Trials', 'Color', 'k')
    timeLabels = cellfun(@(x) num2str(x), num2cell((params.edges(1):.5:params.edges(2)) + params.offset), 'uni', 0);
    leftEdge = params.edges(1)*1000/params.binWidth;
    rightEdge = params.edges(2)*1000/params.binWidth;
    stepSize = .5*1000/params.binWidth;
    timeTix = (leftEdge:stepSize:rightEdge) - leftEdge;
    xticks(timeTix)
    xticklabels(timeLabels)
    % yticks([1 figH.Children.YLim(2) - 1])
    % yticklabels({num2str(figH.Children.YLim(1) + 1), num2str(figH.Children.YLim(2) - 1)})
    set(gca,'FontSize', fontWeight, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k', 'TickDir', 'out', 'LineWidth', 1.5);
end