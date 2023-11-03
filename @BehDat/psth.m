function spikesSmooth=psth(obj, event, neuron, varargin)
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
    validPreset = @(x) isa(x, 'PresetManager');
    p = parse_BehDat('event', 'neuron', 'edges', 'binWidth', 'trialType', 'outcome', 'trials', 'offset', 'panel', 'bpod');
    addParameter(p, 'withinState', [], validStates)
    addParameter(p, 'priorToState', [], validStates)
    addParameter(p, 'excludeEventsByState', [], validStates)
    addParameter(p, 'priorToEvent', [], validEvent)
    addParameter(p, 'plotSEM', true, @islogical)
    addParameter(p, 'preset', [], validPreset)
    parse(p, event, neuron, varargin{:});
    
    if isempty(p.Results.preset)
        a = p.Results;
    else
        a = p.Results.preset;
    end
    plotSEM = p.Results.plotSEM;
    cMap = brewermap([], 'paired');
        % bin spikes in 1 ms bins. If no trialType or outcome param, return all
    % as one matrix
    if (isempty(a.trialType) && isempty(a.outcome) && isempty(a.trials)) || (~iscell(a.trialType) && ~iscell(a.outcome) && ~iscell(a.trials))
        spikeMat = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binWidth', a.binWidth, 'trials', a.trials, ...
            'outcome', a.outcome, 'trialType', a.trialType, 'offset', a.offset, 'bpod', a.bpod, 'priorToEvent', a.priorToEvent, ...
            'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState));
        labelY{1} = "";
        labelY{2} = "All";
    else
        % parse through all inputted trialTypes and outcomes to produce a
        % stacked raster plot of all combos
        if ~iscell(a.trialType)
            a.trialType = num2cell(a.trialType, [1 2]);
        end
        if ~iscell(a.outcome)
            a.outcome = num2cell(a.outcome, [1 2]);
        end
        if ~iscell(a.trials)
            a.trials = num2cell(a.trials, [1 2]);
        end
        numTT = numel(a.trialType);
        numTT(numTT == 0) = 1;
        numOutcomes = numel(a.outcome);
        numOutcomes(numOutcomes == 0) = 1;
        numTrials = numel(a.trials);
        numTrials(numTrials == 0) = 1;
        spikeMat = cell(numel(a.trialType) * numel(a.outcome), 1);
        labelY = cell(size(spikeMat, 1) * 2, 1);
        ctr = 0;
        for tt = 1:numTT
            if numel(a.trialType) == 0
                currentTT = [];
                currentTTString = 'All';
            else
                currentTT = a.trialType{tt};
                currentTTString = currentTT;
            end
            for o = 1:numOutcomes
                if numel(a.outcome) == 0
                    currentOutcome = [];
                    currentOutcomeString = 'All';
                else
                    currentOutcome = a.outcome{o};
                    currentOutcomeString = currentOutcome;
                end
                for tr = 1:numTrials
                    ctr = ctr + 1;
                    if isempty(a.trials)
                        currentTrials = [];
                    else
                        currentTrials = a.trials{tr};
                    end
                    spikeMat{ctr} = boolean(obj.bin_neuron(a.event, a.neuron, 'edges', a.edges, 'binWidth', a.binWidth, 'trials', currentTrials, ...
                    'trialType', currentTT, 'outcome', currentOutcome, 'offset', a.offset, 'bpod', a.bpod, 'priorToEvent', a.priorToEvent, ...
                    'priorToState', a.priorToState, 'withinState', a.withinState, 'excludeEventsByState', a.excludeEventsByState));
                    labelY{ctr*2 - 1} = "";
                    labelY{ctr*2} = strcat(currentTTString, ", ", currentOutcomeString);
                end
            end
        end
    end
    
    if ~iscell(spikeMat)
        spikesSmooth = smoothdata(spikeMat, 2, 'Gaussian', 50)*(1000/a.binWidth);
        spikesSmooth = num2cell(spikesSmooth, [1 2]);
        spikesMean = mean(spikesSmooth{1}, 1);
        spikesMean = num2cell(spikesMean, [1 2]);
        spikesSEM = std(spikesSmooth{1}, 1)/sqrt(size(spikesSmooth{1}, 1));
        spikesSEM = num2cell(spikesSEM, [1 2]);
    else
        spikesSmooth = cellfun(@(x) smoothdata(x, 2, 'Gaussian', 50)*(1000/a.binWidth), spikeMat, 'uni', 0);
        spikesMean = cellfun(@(x) mean(x, 1), spikesSmooth, 'uni', 0);
        spikesSEM = cellfun(@(x) std(x, 1)/sqrt(size(x, 1)), spikesSmooth, 'uni', 0);
    end
    
    if ~isempty(a.panel)
        h = figure('Visible', 'off');
        hold on
        for i = 1:numel(spikesSmooth)
            currentColor = cMap(2*i - 1:2*i, :);
            plot_all_conditions(spikesMean{i}, spikesSEM{i}, plotSEM, currentColor);
        end
        label_psth(obj, h, a, true);
        if plotSEM
            legend(labelY)
        else
            legend(labelY(2:2:end))
        end
%         plot(spikesSmooth)    
        set(gca, 'color', 'w')
        copyobj(h.Children, a.panel)
        close(h)
    else
        h = figure;
        hold on
        for i = 1:numel(spikesSmooth)
            currentColor = cMap(2*i - 1:2*i, :);
            plot_all_conditions(spikesMean{i}, spikesSEM{i}, plotSEM, currentColor);
        end
        label_psth(obj, h, a, false);
        if plotSEM
            legend(labelY)
        else
            legend(labelY(2:2:end))
        end
        set(gca, 'color', 'w')
    end
end

function label_psth(sessObj, figH, params, panel)
    if panel
        fontWeight = 16;
    else
        fontWeight = 24;
        title({sessObj.info.name, ['Neuron ' num2str(params.neuron)]})
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

function [lineh,shadeh]=ShadedErrorPlot(x,means,sem,linecolor,shadecolor,alpha)
    x=reshape(x,length(x),1);
    means=reshape(means,length(means),1);
    sem=reshape(sem,length(sem),1);
    shadeh=fill([x;x(end:-1:1)],[means-sem;means(end:-1:1)+sem(end:-1:1)],shadecolor,'edgecolor',shadecolor,'facealpha',alpha,'edgealpha',alpha);hold on
    if alpha <= .3
        lineStyle = '-';
    else
        lineStyle = '--';
    end
    lineh=semilogx(x,means,'color',linecolor,'LineWidth',1.5, 'LineStyle', lineStyle);hold on
end

function plot_all_conditions(means, sem, addShade, color)
    if addShade
        ShadedErrorPlot(1:numel(means), means, sem, color(2, :), color(1, :), .3);
    else
        plot(means, 'color', color(2, :), 'LineWidth', 1.5);
    end
end