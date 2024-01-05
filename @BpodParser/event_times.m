function eventTimes = event_times(obj, varargin)

% OUTPUT:
%     eventTimes - a 1xT cell array of 1xE timestamps from the desired
%     event, where T is the number of trials and E is the number of events
%     in the given trial.
% INPUT:
% optional name/value pairs:
%     'event' -  a PortIn or PortOut event or regular expression

presets = PresetManager(varargin{:});

rawEvents = obj.session.RawEvents.Trial;

% Identify trials with the event of interest
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), presets.event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);
eventTimes = cellfun(@(x) cat(1, x{:}), eventTimes, 'uni', 0);

if ~isempty(presets.excludeEventsByState)
    % Get cell array of all state times to exclude events within
    goodStates = cellfun(@(x) strcmp(fields(x.States), presets.excludeEventsByState), rawEvents2Check, 'uni', 0);
    trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
    excludeStateTimes = cellfun(@(x, y) x(y), trialCells, goodStates);
    % Find those state times that are nan (did not happen in the trial)
    nanStates = cellfun(@(x) isnan(x(1)), excludeStateTimes);
    % This replaces all the times that were nans with negative state edges
    % since that's something that will never happen in a bpod state and
    % it's easier than removing those trials
    for i = find(nanStates)
        excludeStateTimes{i} = [-2 -1];
    end
    excludeStateTimes = cellfun(@(x) num2cell(x, 2), excludeStateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y, 'uni', 0), eventTimes, excludeStateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x) cat(1, x{:}), timesToRemove, 'uni', 0);
    timesToRemove = cellfun(@(x) any(x == 1, 1), timesToRemove, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(~y), eventTimes, timesToRemove, 'uni', 0);
end

if ~isempty(presets.priorToEvent)
    [sortedNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData2Check.OriginalEventData, 'uni', 0);
    sortedTimes = cellfun(@(x, y) x(y), rawData2Check.OriginalEventTimestamps, eventInds, 'uni', 0); 
    % Event times are now organized chronologically in sortedTimes, with a
    % corresponding cell array for the names of the events
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, eventTimes, 'uni', 0);
    priorToEventTimes = cellfun(@(x) regexp(x, presets.priorToEvent), sortedNames, 'uni', 0);
    priorToEventTimes = cellfun(@(x) cellfun(@(y) ~isempty(y), x), priorToEventTimes, 'uni', 0);
    % Shift priorTo matrix one event to the left, eliminate the last event
    % due to circular shifting, and intersect logical matrices
    eventPrior = cellfun(@(x) circshift(x, -1), priorToEventTimes, 'uni', 0);
    for t = 1:numel(eventPrior)
        try
            eventPrior{t}(end) = false;
        catch
        end
    end
    timesToKeep = cellfun(@(x, y) x & y, currentEventTimes, eventPrior, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(y), sortedTimes, timesToKeep, 'uni', 0);
end

if ~isempty(presets.priorToState)    
    stateNumbers = rawData2Check.OriginalStateData;
    stateNames = rawData2Check.OriginalStateNamesByNumber;
    sortedStateNames = cellfun(@(x, y) x(y), stateNames, stateNumbers, 'uni', 0);
    sortedStateTimes = cellfun(@(x) x(1:end-1), rawData2Check.OriginalStateTimestamps, 'uni', 0);
    [sortedEventNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData2Check.OriginalEventData, 'uni', 0);
    sortedEventTimes = cellfun(@(x, y) x(y), rawData2Check.OriginalEventTimestamps, eventInds, 'uni', 0); 
    eventAndStateTimes = cellfun(@(x, y) [x y], sortedEventTimes, sortedStateTimes, 'uni', 0);
    eventAndStateNames = cellfun(@(x, y) [x y], sortedEventNames, sortedStateNames, 'uni', 0);
    [sortedCombinedTimes, sortedCombinedInds] = cellfun(@(x) sort(x), eventAndStateTimes, 'uni', 0);
    sortedEventAndStateNames = cellfun(@(x, y) x(y), eventAndStateNames, sortedCombinedInds, 'uni', 0);
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedCombinedTimes, eventTimes, 'uni', 0);
    priorToStateTimes = cellfun(@(x) strcmp(x, presets.priorToState), sortedEventAndStateNames, 'uni', 0);
    % Shift priorTo matrix one event to the left, eliminate the last event
    % due to circular shifting, and intersect logical matrices
    eventPriorToState = cellfun(@(x) circshift(x, -1), priorToStateTimes, 'uni', 0);
    for t = 1:numel(eventPriorToState)
        eventPriorToState{t}(end) = false;
    end
    timesToKeep = cellfun(@(x, y) x & y, currentEventTimes, eventPriorToState, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(y), sortedCombinedTimes, timesToKeep, 'uni', 0);
end

if ischar(presets.withinState) || isstring(presets.withinState)
    stateTimes = obj.state_times(presets.withinState);
elseif iscell(presets.withinState)
    stateTimeCell = cellfun(@(x) obj.state_times(x), presets.withinState, 'uni', 0);
    eventIdx = num2cell(1:numel(eventTimes));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);
end

if ~isempty(presets.withinState)
    % This double cellfun operates on withinState which contains a cell for each trial,
    % with a cell for each state inside of that.
    goodTrials = cellfun(@(x) ~isempty(x), eventTimes);
    goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes(goodTrials), eventTimes(goodTrials), 'uni', 0);
    includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
    includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
    includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
    eventCell = cell(size(goodTrials));
    [eventCell{goodTrials}] = deal(includeTimes{:});
    eventTimes = cellfun(@(x, y) x(y), eventTimes, eventCell, 'uni', 0);
end