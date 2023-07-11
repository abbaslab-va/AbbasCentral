function timestamps = find_bpod_event(obj, event, varargin)

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
%     'excludeEventsByState' - a character vector of a state to exclude trials from
%     'withinState' - a character vector, string, or cell array of a state(s) to find the event within
%     'priorToState' - a character vector, string, or cell array of a state(s) to find the event prior to
%     'priorToEvent' - a character vector of an event to find the time prior to

validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validEvent = @(x) isempty(x) || ischar(x) || isstring(x);
p = parse_BehDat('event', 'offset', 'outcome', 'trialType', 'trials');
addParameter(p,'trialized', false, @islogical);
addParameter(p, 'excludeEventsByState', [], validEvent);
addParameter(p, 'withinState', [], validStates);
% addParameter(p, 'priorToState', [], validStates);     % Still need to
% implement this param
addParameter(p, 'priorToEvent', [], validEvent);
parse(p, event, varargin{:});
a = p.Results;
event = a.event;
offset = round(a.offset * obj.info.baud);
outcomeField = a.outcome;
trialTypeField = a.trialType;
trials = a.trials;
trialized = a.trialized;
rawEvents = obj.bpod.RawEvents.Trial;
excludeEventsByState = a.excludeEventsByState;
withinState = a.withinState;
% priorToState = a.priorToState;
priorToEvent = a.priorToEvent;

% Find trial start times in acquisition system timestamps
trialStartTimes = obj.find_event('Trial Start');
% Identify trials with the event of interest
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);
% Initialize trial intersect vectors
numTrialStart = numel(trialStartTimes);
eventTrials = 1:numTrialStart;
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);
trialIncluded = ones(1, numel(eventTrials));
isDesiredTT = trialIncluded;
isDesiredOutcome = trialIncluded;

if ischar(trialTypeField)
    trialTypeField = regexprep(trialTypeField, " ", "_");
    try
        trialTypes = obj.info.trialTypes.(trialTypeField);
        isDesiredTT = ismember(eventTrialTypes, trialTypes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeField));
        throw(mv)
    end
elseif iscell(trialTypeField)
    numTT = numel(trialTypeField);
    intersectMat = zeros(numTT, numel(eventTrials));
    for tt = 1:numTT
        trialTypeString = regexprep(trialTypeField{tt}, " ", "_");
        try
            trialTypes = obj.info.trialTypes.(trialTypeString);
            intersectMat(tt, :) = ismember(eventTrialTypes, trialTypes);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeString));
            throw(mv)
        end
    end
    isDesiredTT = any(intersectMat, 1);
end

if ~isempty(outcomeField)
    outcomeField(outcomeField == ' ') = '_';
    try
        outcomes = obj.info.outcomes.(outcomeField);
        isDesiredOutcome = ismember(eventOutcomes, outcomes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
        throw(mv)
    end
end

if ~isempty(trials)
    trialIncluded = ismember(eventTrials, trials);
end

% Intersect all logical matrices to index bpod trial cells with
goodTrials = isDesiredTT & isDesiredOutcome & trialIncluded;

trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);

eventTimes2Check = eventTimes(goodTrials);
goodEventTimes = cellfun(@(x) [x{:}], eventTimes2Check, 'uni', 0);

if ~isempty(excludeEventsByState)
    % Get cell array of all state times to exclude events within
    goodStates = cellfun(@(x) regexp(fields(x.States), excludeEventsByState), rawEvents2Check, 'uni', 0);
    goodStates = cellfun(@(x) cellfun(@(y) ~isempty(y), x), goodStates, 'uni', 0);
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
    timesToRemove = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y, 'uni', 0), goodEventTimes, excludeStateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x) cat(1, x{:}), timesToRemove, 'uni', 0);
    timesToRemove = cellfun(@(x) any(x == 1, 1), timesToRemove, 'uni', 0);
    goodEventTimes = cellfun(@(x, y) x(~y), goodEventTimes, timesToRemove, 'uni', 0);
end

if ~isempty(priorToEvent)
    allEventNames = cellfun(@(x) fields(x.Events), rawEvents2Check, 'uni', 0);
    allEventTimes = cellfun(@(x) struct2cell(x.Events), rawEvents2Check, 'uni', 0);
    % Ignore any events that are not PortIn or PortOut
    goodEventNames = cellfun(@(x) cellfun(@(y) contains(y, 'Port'), x), allEventNames, 'uni', 0);
    allEventNames = cellfun(@(x, y) x(y), allEventNames, goodEventNames, 'uni', 0);
    allEventTimes = cellfun(@(x, y) x(y), allEventTimes, goodEventNames, 'uni', 0);
    numEvents = cellfun(@(x) cellfun(@(y) numel(y), x, 'uni', 0), allEventTimes, 'uni', 0);
    % Have to deal the names an equal number of times to the number of events
    % per trial so I can sort the times and rearrange the event names based on
    % the sorted times
    repeatedNames = cellfun(@(x) cell(numel(x), 1), numEvents, 'uni', 0);
    for t = 1:numel(repeatedNames)
        trialNames = allEventNames{t};
        for e = 1:numel(trialNames)
            [repeatedNames{t}{e}{1:numEvents{t}{e}}] = deal(allEventNames{t}{e});
        end
    end
    unsortedNames = cellfun(@(x) cat(2, x{:}), repeatedNames, 'uni', 0);
    unsortedTimes = cellfun(@(x) cat(2, x{:}), allEventTimes, 'uni', 0);
    [sortedTimes, sortedIdx] = cellfun(@(x) sort(x), unsortedTimes, 'uni', 0);
    sortedNames = cellfun(@(x, y) x(y), unsortedNames, sortedIdx, 'uni', 0);
    % Event times are now organized chronologically in sortedTimes, with a
    % corresponding cell array for the names of the events
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, goodEventTimes, 'uni', 0);
    priorToEventTimes = cellfun(@(x) regexp(x, priorToEvent), sortedNames, 'uni', 0);
    priorToEventTimes = cellfun(@(x) cellfun(@(y) ~isempty(y), x), priorToEventTimes, 'uni', 0);
    % Shift priorTo matrix one event to the left, eliminate the last event
    % due to circular shifting, and intersect logical matrices
    eventPrior = cellfun(@(x) circshift(x, -1), priorToEventTimes, 'uni', 0);
    for t = 1:numel(eventPrior)
        eventPrior{t}(end) = false;
    end
    timesToKeep = cellfun(@(x, y) x & y, currentEventTimes, eventPrior, 'uni', 0);
    goodEventTimes = cellfun(@(x, y) x(y), sortedTimes, timesToKeep, 'uni', 0);
end

% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, goodEventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = obj.sampling_diff;
eventOffsetCorrected = cellfun(@(x) round(x - x.*averageOffset), eventOffset, 'uni', 0);
eventTimesCorrected = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);

if ischar(withinState) || isstring(withinState)
    stateTimes = obj.find_bpod_state(withinState, 'outcome', outcomeField, 'trialType', trialTypeField, ...
        'trials', trials);
elseif iscell(withinState)
    stateTimeCell = cellfun(@(x) obj.find_bpod_state(x, 'outcome', outcomeField, 'trialType', trialTypeField, ...
        'trials', trials), withinState, 'uni', 0);
    stateTimeCell = cat(1, stateTimeCell{:});
    eventIdx = num2cell(1:numel(eventTimesCorrected));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);
end

if ~isempty(withinState)
    % This double cellfun operates on withinState which contains a cell for each trial,
    % with a cell for each state inside of that.
    goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimesCorrected, 'uni', 0);
    includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
    includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
    includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
    eventTimesCorrected = cellfun(@(x, y) x(y), eventTimesCorrected, includeTimes, 'uni', 0);
end

if trialized 
    timestamps = cellfun(@(x) x + offset, eventTimesCorrected, 'uni', 0);
else
    timestamps = cat(2, eventTimesCorrected{:}) + offset;
end 
