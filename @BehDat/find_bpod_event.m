function timestamps = find_bpod_event(obj, event, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector from the bpod SessionData
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini

p = parse_BehDat('event', 'offset', 'outcome', 'trialType', 'trials');
% addParameter(p, 'priorToState', [], @ischar);
addParameter(p, 'priorToEvent', [], @ischar);
addParameter(p, 'excludeEventsByState', [], @ischar);
addParameter(p,'trialized', false, @islogical);

parse(p, event, varargin{:});
a = p.Results;
event = a.event;
offset = round(a.offset * obj.info.baud);
outcomeField = a.outcome;
trialTypeField = a.trialType;
trials = a.trials;
priorToEvent = a.priorToEvent;
trialized = a.trialized;
rawEvents = obj.bpod.RawEvents.Trial;
excludeEventsByState = a.excludeEventsByState;

% Find trial start times in acquisition system timestamps
trialStartTimes = obj.find_event('Trial Start');
% Identify trials with the event of interest
% trialHasEvent = cellfun(@(x) isfield(x.Events, event), rawEvents);
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);
% Identify trials with the desired performance and trial type
numTrialStart = numel(trialStartTimes);
eventTrials = 1:numTrialStart;
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);
trialIncluded = ones(1, numel(eventTrials));
trialHasEvent = trialIncluded;
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
    trialHasEvent = cellfun(@(x) isfield(x.Events, priorToEvent), rawEvents);
end
% Intersect all logical matrices to index bpod trial cells with
% goodTrials = trialHasEvent & isDesiredTT & isDesiredOutcome & trialIncluded;
goodTrials = trialHasEvent & isDesiredTT & isDesiredOutcome & trialIncluded;


trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);


eventTimes2Check = eventTimes(goodTrials);
bpodEventTimes = cellfun(@(x) [x{:}], eventTimes2Check, 'uni', 0);


% % Need to complete this section
% if ~isempty(priorToEvent)
%     priorToEventTimes = cellfun(@(x) x.Events.(priorToEvent)(1, 1), rawEvents2Check, 'uni', 0);
%     priorToDiff = cellfun(@(x, y) x - y, priorToEventTimes, bpodEventTimes, 'uni', 0);
%     goodTimes = cellfun(@(x) find(x == min(x(x >= 0))), priorToDiff, 'uni', 0);
%     poop = cellfun(@(x, y) x(y), bpodEventTimes, goodTimes);
% end

if ~isempty(excludeEventsByState)
    goodStates = cellfun(@(x) regexp(fields(x.States), excludeEventsByState), rawEvents2Check, 'uni', 0);
    goodStates = cellfun(@(x) cellfun(@(y) ~isempty(y), x), goodStates, 'uni', 0);
    trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
    stateTimes = cellfun(@(x, y) x(y), trialCells, goodStates, 'uni', 0);
    stateTimesToExclude = cellfun(@(x) cat(1, x{:}), stateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x, y) ismember(x, y), bpodEventTimes, stateTimesToExclude, 'uni', 0);
    bpodEventTimes = cellfun(@(x, y) x(~y), bpodEventTimes, timesToRemove, 'uni', 0);
end


% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, bpodEventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor that bpod outpaces the blackrock system by, .0136
eventOffsetCorrected = cellfun(@(x) x - x.*.0136, eventOffset, 'uni', 0);
 eventTimes = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);
%eventTimes = cellfun(@(x, y) x + y, trialStartTimes, eventOffset, 'uni', 0);


if trialized 
    timestamps = cellfun(@(x) x + offset, eventTimes, 'uni', 0);
else
    timestamps = cat(2, eventTimes{:}) + offset;
end 
