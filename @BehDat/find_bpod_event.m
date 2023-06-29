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
addParameter(p, 'priorToState', [], validStates);
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
priorToState = a.priorToState;
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
eventInTrial = trialIncluded;
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

if ~isempty(priorToEvent)
    eventInTrial = cellfun(@(x) isfield(x.Events, priorToEvent), rawEvents);
end
% Intersect all logical matrices to index bpod trial cells with
goodTrials = eventInTrial & isDesiredTT & isDesiredOutcome & trialIncluded;

trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);

eventTimes2Check = eventTimes(goodTrials);
bpodEventTimes = cellfun(@(x) [x{:}], eventTimes2Check, 'uni', 0);

if ~isempty(excludeEventsByState)
    goodStates = cellfun(@(x) regexp(fields(x.States), excludeEventsByState), rawEvents2Check, 'uni', 0);
    goodStates = cellfun(@(x) cellfun(@(y) ~isempty(y), x), goodStates, 'uni', 0);
    trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
    excludeStateTimes = cellfun(@(x, y) x(y), trialCells, goodStates, 'uni', 0);
    timesToRemove = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y, 'uni', 0), bpodEventTimes, excludeStateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x) cat(1, x{:}), timesToRemove, 'uni', 0);
    timesToRemove = cellfun(@(x) any(x == 1, 1), timesToRemove, 'uni', 0);
    bpodEventTimes = cellfun(@(x, y) x(~y), bpodEventTimes, timesToRemove, 'uni', 0);
end


% % Need to complete this section
% if ~isempty(priorToEvent)
%     priorToEventTimes = cellfun(@(x) x.Events.(priorToEvent)(1, 1), rawEvents2Check, 'uni', 0);
%     priorToDiff = cellfun(@(x, y) x - y, priorToEventTimes, bpodEventTimes, 'uni', 0);
%     goodTimes = cellfun(@(x) find(x == min(x(x >= 0))), priorToDiff, 'uni', 0);
%     poop = cellfun(@(x, y) x(y), bpodEventTimes, goodTimes);
% end


% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, bpodEventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = obj.sampling_diff;
eventOffsetCorrected = cellfun(@(x) round(x - x.*averageOffset), eventOffset, 'uni', 0);
eventTimes = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);

if ischar(withinState) || isstring(withinState)
    stateTimes = obj.find_bpod_state(withinState, 'outcome', outcomeField, 'trialType', trialTypeField, ...
        'trials', trials);
elseif iscell(withinState)
    stateTimeCell = cellfun(@(x) obj.find_bpod_state(x, 'outcome', outcomeField, 'trialType', trialTypeField, ...
        'trials', trials), withinState, 'uni', 0);
    stateTimeCell = cat(1, stateTimeCell{:});
    eventIdx = num2cell(1:numel(eventTimes));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);
end

if ~isempty(withinState)
    % This double cellfun operates on withinState which contains a cell for each trial,
    % with a cell for each state inside of that.
    goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimes, 'uni', 0);
    includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
    includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
    includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(y), eventTimes, includeTimes, 'uni', 0);
end

if trialized 
    timestamps = cellfun(@(x) x + offset, eventTimes, 'uni', 0);
else
    timestamps = cat(2, eventTimes{:}) + offset;
end 
