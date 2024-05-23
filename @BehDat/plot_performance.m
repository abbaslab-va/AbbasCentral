function figH = plot_performance(obj, outcome, varargin)

    % Plots bpod performance bar chart by trial type
    % INPUT:
    %     outcome - the outcome whos percentage is being visualized
    %     panel - a panel handle from AbbasCentral (optional)
    
    [trials, correct] = bpod_performance(obj.bpod, outcome);
    pctCorrect = correct./trials * 100;
    
    presets = PresetManager(varargin{:});
    
    if isempty(presets.panel)
        figH = figure;
        bar(pctCorrect)
        ylim([0 100])
        label_performance(obj, figH, presets)
    else
        figH = figure('Visible', 'off');
        bar(pctCorrect)
        ylim([0 100])
        label_performance(obj, figH, presets)
        copyobj(figH.Children, presets.panel)
        close(figH)
    end
end

function figH = label_performance(sessObj, figH, params)
allTT = cellfun(@(x) sessObj.info.trialTypes.(x), fields(sessObj.info.trialTypes), 'uni', 0);
allTT = cat(2, allTT{:});
allTT = 1:numel(unique(allTT));
    if ~isempty(params.panel)
        fontWeight = 16;
    else
        fontWeight = 24;
        title(sessObj.info.name)
    end
    if ~isempty(params.trialType)
        if ~iscell(params.trialType)
            ttVals = sessObj.info.trialTypes.(params.trialType);
        else
            numTrialTypes = numel(params.trialType);
            ttVals = cell(1, numTrialTypes);
            for i = 1:numTrialTypes
                ttVals{i} = sessObj.info.trialTypes.(params.trialType{i});
            end
            ttVals = cat(2, ttVals{:});
            ttVals = unique(ttVals);
        end
        x = allTT;
        notX = allTT(~ismember(allTT, ttVals));
        y(ttVals) = figH.Children.Children.YData(ttVals);
        y(notX) = 0;
        hold on
        bar(x, y, 'r')
    end
    xlabel('Trial Type', 'Color', 'k')
    ylabel('Percent Correct', 'Color', 'k')
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