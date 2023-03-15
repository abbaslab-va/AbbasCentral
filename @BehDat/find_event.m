function timestamps = find_event(obj, event, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector found in the config.ini file
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
offset = a.offset;
outcomeField = a.outcome;
trialTypeField = a.trialType;
offset = offset * obj.info.baud;
event(event == ' ') = '_';
try
    timestamp = obj.timestamps.keys.(event);
catch
    mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', event));
    throw(mv)
end
timestamps = obj.timestamps.times(obj.timestamps.codes == timestamp) + offset;

eventTrials = discretize(timestamps, [obj.timestamps.trialStart obj.info.samples]);
eventTrials = eventTrials(eventTrials <= obj.bpod.nTrials);
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);
isDesiredTT = ones(1, numel(eventTrials));
isDesiredOutcome = ones(1, numel(eventTrials));


if ~isempty(trialTypeField)
%     trialTypeField = append("x_", trialTypeField);
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
%     outcomeField = append("x_", outcomeField);
    outcomeField(outcomeField == ' ') = '_';
    try
        outcomes = obj.info.outcomes.(outcomeField);
        isDesiredOutcome = ismember(eventOutcomes, outcomes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
        throw(mv)
    end
end

timestamps = timestamps(isDesiredTT & isDesiredOutcome);