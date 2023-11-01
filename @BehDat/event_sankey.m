function event_sankey(obj, varargin)

% This function outputs a sankey plot showing the transitions between bpod
% states. By default, it displays all state transitions from all trial
% types, but users can use name-value pairs to only analyze certain
% combinations of trial types and outcomes, as well as only transitions to
% or from a certain state.
% 
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'inputStates' - a string or cell array of strings of desired input
%     states to visualize
%     'outputStates' - a string or cell array of strings of desired output
%     states to visualize

session = obj.bpod;
defaultInput = {'Port1In', 'Port1Out', 'Port2In', 'Port2Out', 'Port3In', 'Port3Out',...
    'Port4In', 'Port4Out', 'Port5In', 'Port5Out', 'Port6In', 'Port6Out',...
    'Port7In', 'Port7Out', 'Port8In', 'Port8Out'};              % all input events
defaultOutput = defaultInput;                                   % all output events
validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validState = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);

p = parse_BehDat('outcome', 'trialType', 'trials');
addParameter(p, 'inputEvents', defaultInput, validField);
addParameter(p, 'outputEvents', defaultOutput, validField);
addParameter(p, 'inputWithinState', [], validState);
parse(p, varargin{:});
a = p.Results;

trialsToInclude = find(obj.trial_intersection(1:obj.bpod.nTrials, a.outcome, a.trialType, a.trials));

rawEvents2Check = obj.bpod.RawEvents.Trial(trialsToInclude);
startEvent = cell(0);
endEvent = cell(0);

if ~isempty(a.inputWithinState)
    % Get cell array of all state times to exclude events within
    goodStates = cellfun(@(x) strcmp(fields(x.States), a.inputWithinState), rawEvents2Check, 'uni', 0);
    trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
    includeStateTimes = cellfun(@(x, y) x(y), trialCells, goodStates);
    % Find those state times that are nan (did not happen in the trial)
    nanStates = cellfun(@(x) isnan(x(1)), includeStateTimes);
    % This replaces all the times that were nans with negative state edges
    % since that's something that will never happen in a bpod state and
    % it's easier than removing those trials
    for i = find(nanStates)
        includeStateTimes{i} = [-2 -1];
    end
    for f = find(~nanStates)
        trialEndTime = session.TrialEndTimestamp(f) - session.TrialStartTimestamp(f);
        for e = 1:numel(includeStateTimes(f))
            includeStateTimes{f}(e, 2) = trialEndTime;
        end
    end
    includeStateTimes = cellfun(@(x) num2cell(x, 2), includeStateTimes, 'uni', 0);
end

for trial = trialsToInclude
    trialEvents = session.RawData.OriginalEventData{trial};
    [eventNames, eventInds] = map_bpod_events(trialEvents);
    eventTimes = session.RawData.OriginalEventTimestamps{trial}(eventInds);
    if exist('includeStateTimes', 'var')
        goodTimes = includeStateTimes{trial};
        goodEventTimes = cellfun(@(x) discretize(eventTimes, x), goodTimes, 'uni', 0);
        goodEventTimes = cat(1, goodEventTimes{:});
        eventTimes2Check = ~isnan(goodEventTimes);
        for row = 1:size(eventTimes2Check, 1)
            firstEventTimes = find(eventTimes2Check(row, :), 1, 'first');
            eventTimes2Check(row, firstEventTimes+1:end) = false;
        end
        eventTimes2Check = any(eventTimes2Check, 1);
    else
        goodEventTimes = eventTimes;
        eventTimes2Check = ~isnan(goodEventTimes);
        eventTimes2Check = any(eventTimes2Check, 1);
    end    

    for event = 1:numel(eventTimes2Check)-1
        if ~eventTimes2Check(event)
            continue
        end
        if any(strcmp(a.inputEvents, eventNames{event})) && any(strcmp(a.outputEvents, eventNames{event+1}))
            startEvent{end+1} = eventNames{event};
            endEvent{end+1} = eventNames{event+1};
        end
    end
end

startEvent = categorical(startEvent');
endEvent = categorical(endEvent');
t = table(startEvent, endEvent, 'VariableNames', ["Start", "End"]);

options.color_map = 'parula';      
options.flow_transparency = 0.2;   % opacity of the flow paths
options.bar_width = 120;            % width of the category blocks
options.show_perc = false;          % show percentage over the blocks
options.text_color = [0 0 0];      % text color for the percentages
options.show_layer_labels = true;  % show layer names under the chart
options.show_cat_labels = true;   % show categories over the blocks.
options.show_legend = false;    

plotSankeyFlowChart(t, options);

