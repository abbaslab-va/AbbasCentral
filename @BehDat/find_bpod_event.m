function timestamps = find_bpod_event(obj, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector from the bpod SessionData
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers to include
%     'trialized' - a logical that determines whether to return a cell array of timestamps for each trial or a vector of all timestamps
%     'excludeState' - a character vector of a state to exclude trials from
%     'withinState' - a character vector, string, or cell array of a state(s) to find the event within
%     'priorToState' - a character vector, string, or cell array of a state(s) to find the event prior to
%     'priorToEvent' - a character vector of an event to find the time prior to

presets = PresetManager(varargin{:});

offset = round(presets.offset * obj.info.baud);
if isa(obj.bpod, 'BpodParser')
    bpodStruct = obj.bpod.session;
else
    bpodStruct = obj.bpod;
end
rawEvents = bpodStruct.RawEvents.Trial;
rawData = bpodStruct.RawData;

% Find trial start times in acquisition system timestamps
try
    trialStartTimes = obj.timestamps.trialStart;
catch
    trialStartTimes = obj.find_event('event', 'Trial Start');
end
    % Identify trials with the event of interest
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), presets.event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);

numTrialStart = numel(trialStartTimes);
eventTrials = 1:numTrialStart;
% Intersect all logical matrices to index bpod trial cells with
goodTrials = obj.trial_intersection(eventTrials, presets);

trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);
rawData2Check = structfun(@(x) x(goodTrials), rawData, 'uni', 0);
eventTimes2Check = eventTimes(goodTrials);
goodEventTimes = cellfun(@(x) [x{:}], eventTimes2Check, 'uni', 0);

if ~isempty(presets.excludeState)
    if ~iscell(presets.excludeState)
        presets.excludeState=mat2cell(presets.excludeState,1);
    end 
    % Get cell array of all state times to exclude events within
    goodStates = cellfun(@(x) cellfun(@(y)strcmp(fields(y.States),x),rawEvents2Check,'uni',0), presets.excludeState, 'uni', 0);
    trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
    excludeStateTimes = cellfun(@(z) cellfun(@(x, y) x(y), trialCells, z),goodStates,'uni',0);
    % Find those state times that are nan (did not happen in the trial)
    nanStates = cellfun(@(w) cellfun(@(x) isnan(x(1)), w),excludeStateTimes,'uni',0);
    % This replaces all the times that were nans with negative state edges
    % since that's something that will never happen in a bpod state and
    % it's easier than removing those trials
    for c=1:numel(presets.excludeState)
        for i = find(nanStates{c})
            excludeStateTimes{c}{i} = [-2 -1];
        end
        excludeStateTimes{c} = cellfun(@(x) num2cell(x, 2), excludeStateTimes{c}, 'uni', 0);
        timesToRemove = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y, 'uni', 0), goodEventTimes, excludeStateTimes{c}, 'uni', 0);
        timesToRemove = cellfun(@(x) cat(1, x{:}), timesToRemove, 'uni', 0);
        timesToRemove = cellfun(@(x) any(x == 1, 1), timesToRemove, 'uni', 0);
        goodEventTimes = cellfun(@(x, y) x(~y), goodEventTimes, timesToRemove, 'uni', 0);
    end 
end

if ~isempty(presets.priorToEvent)
    [sortedNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData2Check.OriginalEventData, 'uni', 0);
    sortedTimes = cellfun(@(x, y) x(y), rawData2Check.OriginalEventTimestamps, eventInds, 'uni', 0); 
    % Event times are now organized chronologically in sortedTimes, with a
    % corresponding cell array for the names of the events
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, goodEventTimes, 'uni', 0);
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
    goodEventTimes = cellfun(@(x, y) x(y), sortedTimes, timesToKeep, 'uni', 0);
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
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedCombinedTimes, goodEventTimes, 'uni', 0);
    priorToStateTimes = cellfun(@(x) strcmp(x, presets.priorToState), sortedEventAndStateNames, 'uni', 0);
    % Shift priorTo matrix one event to the left, eliminate the last event
    % due to circular shifting, and intersect logical matrices
    eventPriorToState = cellfun(@(x) circshift(x, -1), priorToStateTimes, 'uni', 0);
    for t = 1:numel(eventPriorToState)
        eventPriorToState{t}(end) = false;
    end
    timesToKeep = cellfun(@(x, y) x & y, currentEventTimes, eventPriorToState, 'uni', 0);
    goodEventTimes = cellfun(@(x, y) x(y), sortedCombinedTimes, timesToKeep, 'uni', 0);
end

% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, goodEventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = num2cell(obj.sampling_diff(presets));
eventOffsetCorrected = cellfun(@(x, y) round(x - x.*y), eventOffset, averageOffset, 'uni', 0);
eventTimesCorrected = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);

if ischar(presets.withinState) || isstring(presets.withinState)
    stateTimes = obj.find_bpod_state(presets.withinState, 'preset', presets);
elseif iscell(presets.withinState)
    stateTimeCell = cellfun(@(x) obj.find_bpod_state(x, 'preset', presets), presets.withinState, 'uni', 0);
    stateTimeCell = cat(1, stateTimeCell{:});
    eventIdx = num2cell(1:numel(eventTimesCorrected));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);
end

if ~isempty(presets.withinState)
    % This double cellfun operates on withinState which contains a cell for each trial,
    % with a cell for each state inside of that.
    goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimesCorrected, 'uni', 0);
    includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
    includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
    includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
    eventTimesCorrected = cellfun(@(x, y) x(y), eventTimesCorrected, includeTimes, 'uni', 0);
end

if presets.trialized 
    timestamps = cellfun(@(x) x + offset, eventTimesCorrected, 'uni', 0);
else
    timestamps = cat(2, eventTimesCorrected{:}) + offset;
end 
