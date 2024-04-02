function spikesSmooth = psth(obj, neuron, varargin)
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
        
    presets = PresetManager(varargin{:});
    plotSEM = true;     % Removed this as param because all params now have to pass to PresetManager, and if the varargin is not a valid parameter, it returns an error. Not sure how to deal with this yet
    cMap = brewermap([], 'paired');
        % bin spikes in 1 ms bins. If no trialType or outcome param, return all
    % as one matrix
    if (isempty(presets.trialType) && isempty(presets.outcome) && isempty(presets.trials) && isempty(presets.stimType)) ...
            || (~iscell(presets.trialType) && ~iscell(presets.outcome) && ~iscell(presets.trials) && ~iscell(presets.stimType))
        spikeMat = logical(obj.bin_neuron(neuron, 'preset', presets));
        labelY{1} = "";
        labelY{2} = "All";
    else
        % parse through all inputted trialTypes and outcomes to produce a
        % stacked raster plot of all combos
        if ~iscell(presets.trialType)
            presets.trialType = num2cell(presets.trialType, [1 2]);
        end
        if ~iscell(presets.outcome)
            presets.outcome = num2cell(presets.outcome, [1 2]);
        end
        if ~iscell(presets.stimType)
            presets.stimType = num2cell(presets.stimType, [1 2]);
        end
        if ~iscell(presets.trials)
            presets.trials = num2cell(presets.trials, [1 2]);
        end
        numTT = numel(presets.trialType);
        numTT(numTT == 0) = 1;
        numOutcomes = numel(presets.outcome);
        numOutcomes(numOutcomes == 0) = 1;
        numStim = numel(presets.stimType);
        numStim(numStim == 0) = 1;
        numTrials = numel(presets.trials);
        numTrials(numTrials == 0) = 1;
        spikeMat = cell(numTT * numOutcomes * numStim * numTrials, 1);
        labelY = cell(size(spikeMat, 1) * 2, 1);
        ctr = 0;
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
                for s = 1:numStim
                    if numel(presets.stimType) == 0
                        currentStim = [];
                        currentStimString = 'All';
                    else
                        currentStim = presets.stimType{s};
                        currentStimString = currentStim;
                    end
                    for tr = 1:numTrials
                        ctr = ctr + 1;
                        if isempty(presets.trials)
                            currentTrials = [];
                        else
                            currentTrials = presets.trials{tr};
                        end
                        spikeMat{ctr} = logical(obj.bin_neuron(neuron, 'event', presets.event, 'edges', presets.edges, 'binWidth', presets.binWidth, 'trials', currentTrials, ...
                        'trialType', currentTT, 'outcome', currentOutcome, 'stimType', currentStim, 'offset', presets.offset, 'bpod', presets.bpod, 'priorToEvent', presets.priorToEvent, ...
                        'priorToState', presets.priorToState, 'withinState', presets.withinState, 'excludeState', presets.excludeState));
                        labelY{ctr*2 - 1} = "";
                        labelY{ctr*2} = strcat(currentTTString, ", ", currentOutcomeString, ", ", currentStimString);
                    end
                end
            end
        end
    end
    
    if ~iscell(spikeMat)
        spikesSmooth = smoothdata(spikeMat, 2, 'Gaussian', 50)*(1000/presets.binWidth);
        spikesSmooth = num2cell(spikesSmooth, [1 2]);
        spikesMean = mean(spikesSmooth{1}, 1);
        spikesMean = num2cell(spikesMean, [1 2]);
        spikesSEM = std(spikesSmooth{1}, 1)/sqrt(size(spikesSmooth{1}, 1));
        spikesSEM = num2cell(spikesSEM, [1 2]);
    else
        spikesSmooth = cellfun(@(x) smoothdata(x, 2, 'Gaussian', 50)*(1000/presets.binWidth), spikeMat, 'uni', 0);
        spikesMean = cellfun(@(x) mean(x, 1), spikesSmooth, 'uni', 0);
        spikesSEM = cellfun(@(x) std(x, 1)/sqrt(size(x, 1)), spikesSmooth, 'uni', 0);
    end
    
    if ~isempty(presets.panel)
        h = figure('Visible', 'off');
        hold on
        for i = 1:numel(spikesSmooth)
            currentColor = cMap(2*i - 1:2*i, :);
            plot_all_conditions(spikesMean{i}, spikesSEM{i}, plotSEM, currentColor);
        end
        label_psth(obj, h, neuron, presets, true);
        if plotSEM
            legend(labelY)
        else
            legend(labelY(2:2:end))
        end
%         plot(spikesSmooth)    
        set(gca, 'color', 'w')
        copyobj(h.Children, presets.panel)
        close(h)
    else
        h = figure;
        hold on
        for i = 1:numel(spikesSmooth)
            currentColor = cMap(2*i - 1:2*i, :);
            plot_all_conditions(spikesMean{i}, spikesSEM{i}, plotSEM, currentColor);
        end
        label_psth(obj, h, neuron, presets, false);
        if plotSEM
            legend(labelY)
        else
            legend(labelY(2:2:end))
        end
        set(gca, 'color', 'w')
    end
end

function label_psth(sessObj, figH, neuron, params, panel)
    if panel
        fontWeight = 16;
    else
        fontWeight = 24;
        title({sessObj.info.name, ['Neuron ' num2str(neuron)]})
    end
    xlabel('Time From Event (sec)', 'Color', 'k')
    ylabel('Firing Rate (hz)', 'Color', 'k')
    timeLabels = cellfun(@(x) num2str(x), num2cell((params.edges(1):.5:params.edges(2)) + params.offset), 'uni', 0);
    leftEdge = params.edges(1)*1000/params.binWidth;
    rightEdge = params.edges(2)*1000/params.binWidth;
    stepSize = .5*1000/params.binWidth;
    timeTix = (leftEdge:stepSize:rightEdge) - leftEdge;
    xticks(timeTix)
    xticklabels(timeLabels)
    yticks([0 round(figH.Children.YLim(2))])
    set(gca,'FontSize', fontWeight, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k', 'TickDir', 'out', 'LineWidth', 1.5);
end   

function plot_all_conditions(means, sem, addShade, color)
    if addShade
        shaded_error_plot(1:numel(means), means, sem, color(2, :), color(1, :), .3);
    else
        plot(means, 'color', color(2, :), 'LineWidth', 1.5);
    end
end