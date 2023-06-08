function stateEdges = find_bpod_state(obj, stateName, varargin)
 
% OUTPUT:
%     stateEdges - a 1xN cell array of state edges where N is the number of trials.
% 
% INPUTS:
%     stateName - a name of a bpod state to find edges for in the acquisition system's sampling rate
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers to include


p = parse_BehDat('outcome', 'trialType', 'trials');
addRequired(p, 'stateName', @ischar);

parse(p, stateName, varargin{:});
a = p.Results;
stateName = a.stateName;
trialType = a.trialType;
outcome = a.outcome;
trials = a.trials;
rawEvents = obj.bpod.RawEvents.Trial;
numTrialStart = numel(obj.timestamps.trialStart);
eventTrials = 1:numTrialStart;
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);

correctTrialType = true(1, obj.bpod.nTrials);
correctOutcome = true(1, obj.bpod.nTrials);
trialIncluded = true(1, obj.bpod.nTrials);
if ~isempty(trialType)
    ttToIndex = obj.info.trialTypes.(trialType);
    correctTrialType = ismember(eventTrialTypes, ttToIndex);
end

if ~isempty(outcome)
    outcomeToIndex = obj.info.outcomes.(outcome);
    correctOutcome = ismember(eventOutcomes, outcomeToIndex);
end

if ~isempty(trials)
    trialIncluded = ismember(eventTrials, trials); 
end

goodTrials = correctTrialType & correctOutcome & trialIncluded;
rawEvents2Check = rawEvents(goodTrials);

fieldNames = cellfun(@(x) fields(x.States), rawEvents2Check, 'uni', 0);

fieldsToIndex = cellfun(@(x) regexp(x, stateName), fieldNames, 'uni', 0);
fieldsToIndex = cellfun(@(x) cellfun(@(y) ~isempty(y), x), fieldsToIndex, 'uni', 0);

trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
stateTimesBpod = cellfun(@(x, y) x(y), trialCells, fieldsToIndex, 'uni', 0);
% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
stateOffset = cellfun(@(x, y) cellfun(@(z) round((z - y) * obj.info.baud), x, 'uni', 0), stateTimesBpod, bpodStartTimes, 'uni', 0);
stateOffset = cellfun(@(x) cat(1, x{:}), stateOffset, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = obj.samplingDiff;
stateOffsetCorrected = cellfun(@(x) round(x - x.*averageOffset), stateOffset, 'uni', 0);
trialStartTimes = num2cell(obj.timestamps.trialStart(goodTrials));
stateTimes = cellfun(@(x, y) x + y, trialStartTimes, stateOffsetCorrected, 'uni', 0);

stateEdges = cellfun(@(x) x(all(~isnan(x), 2), :), stateTimes, 'uni', 0);
stateEdges = cellfun(@(x) num2cell(x, 2), stateEdges, 'uni', 0);
