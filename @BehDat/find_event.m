function [timestamps, bpodTrials] = find_event(obj, event, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector found in the config.ini file
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini

validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = parse_BehDat('event', 'offset', 'outcome', 'trialType', 'trials');
addParameter(p,'trialized', false, @islogical);
% Need to implement withinState as param for app - don't necesessarily need
% to flesh it out here
addParameter(p, 'withinState', [], validStates)
parse(p, event, varargin{:});
a = p.Results;
event = a.event;
offset = round(a.offset * obj.info.baud);
outcomeField = a.outcome;
trialTypeField = a.trialType;
trials = a.trials;
trialized = a.trialized;

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

if ischar(outcomeField)
    outcomeField = regexprep(outcomeField, " ", "_");
    try
        outcomes = obj.info.outcomes.(outcomeField);
        isDesiredOutcome = ismember(eventOutcomes, outcomes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
        throw(mv)
    end
elseif iscell(outcomeField)
    numOutcomes = numel(outcomeField);
    intersectMat = zeros(numOutcomes, numel(eventTrials));
    for o = 1:numOutcomes
        outcomeString = regexprep(outcomeField{o}, " ", "_");
        try
            outcomes = obj.info.outcomes.(outcomeString);
            intersectMat(o, :) = ismember(eventOutcomes, outcomes);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeString));
            throw(mv)
        end
    end
    isDesiredOutcome = any(intersectMat, 1);
end

% if ~isempty(outcomeField)
%     outcomeField(outcomeField == ' ') = '_';
%     try
%         outcomes = obj.info.outcomes.(outcomeField);
%         isDesiredOutcome = ismember(eventOutcomes, outcomes);
%     catch
%         mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
%         throw(mv)
%     end
% end

if ~isempty(trials)
    trialIncluded = ismember(eventTrials, trials);
end

bpodTrials = isDesiredTT & isDesiredOutcome & trialIncluded;
timestamps = timestamps(bpodTrials);

if trialized  
    eventTrial=discretize(timestamps,[obj.timestamps.trialStart obj.info.samples]);
    temp=timestamps;
    trialNo = unique(eventTrial);
    timestamps=cell(1,numel(trialNo));
    for t = trialNo
        timestamps{t} = temp(eventTrial == t);
    end
end 