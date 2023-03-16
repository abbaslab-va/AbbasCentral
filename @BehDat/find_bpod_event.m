function timestamps = find_bpod_event(obj, event, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector from the bpod SessionData
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini

defaultOffset = 0;
defaultOutcome = [];
defaultTrialTypes = [];

validField = @(x) ischar(x) || isempty(x);
p = inputParser;
addRequired(p, 'event', @ischar);
addParameter(p, 'offset', defaultOffset, @isnumeric);
addParameter(p, 'outcome', defaultOutcome, validField);
addParameter(p, 'trialType', defaultTrialTypes, validField);
parse(p, event, varargin{:});
a = p.Results;
event = a.event;
offset = round(a.offset * obj.info.baud);
outcomeField = a.outcome;
trialTypeField = a.trialType;
rawEvents = obj.bpod.RawEvents.Trial;

% Find trial start times in acquisition system timestamps
trialStartTimes = obj.find_event('Trial Start');
% Identify trials with the event of interest
trialHasEvent = cellfun(@(x) isfield(x.Events, event), rawEvents);
% Identify trials with the desired performance and trial type
numTrialStart = numel(trialStartTimes);
eventTrials = 1:numTrialStart;
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);
isDesiredTT = ones(1, numTrialStart);
isDesiredOutcome = ones(1, numTrialStart);

if ~isempty(trialTypeField)
    trialTypeField = regexprep(trialTypeField, " ", "_");
    try
        trialTypes = obj.info.trialTypes.(trialTypeField);
        isDesiredTT = ismember(eventTrialTypes, trialTypes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeField));
        throw(mv)
    end
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

% Intersect all logical matrices to index bpod trial cells with
goodTrials = trialHasEvent & isDesiredTT & isDesiredOutcome;

trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);
% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, bpodEventTimes, bpodStartTimes, 'uni', 0);
eventTimes = cellfun(@(x, y) x + y, trialStartTimes, eventOffset, 'uni', 0);

timestamps = cat(2, eventTimes{:}) + offset;