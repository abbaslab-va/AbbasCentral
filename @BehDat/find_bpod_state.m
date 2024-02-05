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

presets = PresetManager(varargin{:});

if isa(obj.bpod, 'BpodParser')
    bpodSess = obj.bpod.session;
else
    bpodSess = obj.bpod;
end
rawEvents = bpodSess.RawEvents.Trial;
numTrialStart = numel(obj.timestamps.trialStart);
eventTrials = 1:numTrialStart;
eventTrialTypes = bpodSess.TrialTypes(eventTrials);
eventOutcomes = bpodSess.SessionPerformance(eventTrials);

correctTrialType = true(1, bpodSess.nTrials);
correctOutcome = true(1, bpodSess.nTrials);
trialIncluded = true(1, bpodSess.nTrials);
if ~isempty(presets.trialType)
    presets.trialType = regexprep(presets.trialType, " ", "_");
    ttToIndex = obj.info.trialTypes.(presets.trialType);
    correctTrialType = ismember(eventTrialTypes, ttToIndex);
end

if ~isempty(presets.outcome)
    presets.outcome = regexprep(presets.outcome, " ", "_");
    outcomeToIndex = obj.info.outcomes.(presets.outcome);
    correctOutcome = ismember(eventOutcomes, outcomeToIndex);
end

if ~isempty(presets.trials)
    trialIncluded = ismember(eventTrials, presets.trials); 
end

goodTrials = obj.trial_intersection(eventTrials, presets);
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
averageOffset = num2cell(obj.sampling_diff(presets));
stateOffsetCorrected = cellfun(@(x, y) round(x - x.*y), stateOffset, averageOffset, 'uni', 0);
trialStartTimes = num2cell(obj.timestamps.trialStart(goodTrials));
stateTimes = cellfun(@(x, y) x + y, trialStartTimes, stateOffsetCorrected, 'uni', 0);

stateEdges = cellfun(@(x) x(all(~isnan(x), 2), :), stateTimes, 'uni', 0);
stateEdges = cellfun(@(x) num2cell(x, 2), stateEdges, 'uni', 0);
