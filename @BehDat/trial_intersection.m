function goodTrials = trial_intersection(obj, trializedEvents, outcomes, trialTypes, trials)

% Abstracts away some complexity from the find_event and find_bpod_event
% functions. Calculates trial set intersections
% 
% OUTPUT:
%     goodTrials - logical vector for indexing trial sets
% INPUT:
%     trializedEvents - discretized event trial numbers
%     outcomes - outcomes found in config.ini
%     trialTypes - trial types found in config.ini
%     trials - a vector of trial numbers to include

numEvents = numel(trializedEvents);
eventTrialTypes = obj.bpod.TrialTypes(trializedEvents);
eventOutcomes = obj.bpod.SessionPerformance(trializedEvents);

%% Trial Types
if ischar(trialTypes)
    trialTypes = {trialTypes};
end

if isempty(trialTypes)
    isDesiredTT = ones(1, numEvents);
else
    numTT = numel(trialTypes);
    intersectMat = zeros(numTT, numEvents);
    for tt = 1:numTT
        trialTypeString = regexprep(trialTypes{tt}, " ", "_");
        try
            trialTypeVal = obj.info.trialTypes.(trialTypeString);
            intersectMat(tt, :) = ismember(eventTrialTypes, trialTypeVal);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeString));
            throw(mv)
        end
    end
    isDesiredTT = any(intersectMat, 1);
end
%% Outcomes
if ischar(outcomes)
    outcomes = {outcomes};
end

if isempty(outcomes)
    isDesiredOutcome = ones(1, numEvents);
else
    numOutcomes = numel(outcomes);
    intersectMat = zeros(numOutcomes, numEvents);
    for o = 1:numOutcomes
        outcomeString = regexprep(outcomes{o}, " ", "_");
        try
            outcomeVal = obj.info.outcomes.(outcomeString);
            intersectMat(o, :) = ismember(eventOutcomes, outcomeVal);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeString));
            throw(mv)
        end
    end
    isDesiredOutcome = any(intersectMat, 1);
end

%% Trial numbers
if isempty(trials)
    trialIncluded = ones(1, numEvents);
else
    trialIncluded = ismember(1:numTrials, numEvents);
end

goodTrials = isDesiredTT & isDesiredOutcome & trialIncluded;
