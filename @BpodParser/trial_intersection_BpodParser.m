function goodTrials = trial_intersection_BpodParser(obj, trializedEvents, presets)

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
bpodStruct = obj.session;
eventTrialTypes = bpodStruct.TrialTypes(trializedEvents);
eventOutcomes = bpodStruct.SessionPerformance(trializedEvents);

if isfield(bpodStruct, 'StimTypes')
    eventStimTypes = bpodStruct.StimTypes(trializedEvents);
    stimTypes = presets.stimType;
else
    stimTypes = [];
end
    
trialTypes = presets.trialType;
outcomes = presets.outcome;
trials = presets.trials;


%% Trial Types
if ischar(trialTypes)
    trialTypes = {trialTypes};
end

if isempty(trialTypes)
    isDesiredTT = true(1, numEvents);
else
    numTT = numel(trialTypes);
    intersectMatTT = zeros(numTT, numEvents);
    for tt = 1:numTT
        trialTypeString = regexprep(trialTypes{tt}, " ", "_");
        try
            trialTypeVal = obj.info.trialTypes.(trialTypeString);
            intersectMatTT(tt, :) = ismember(eventTrialTypes, trialTypeVal);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeString));
            throw(mv)
        end
    end
    isDesiredTT = any(intersectMatTT, 1);
end

%% Stim Types
if ischar(stimTypes)
    stimTypes = {stimTypes};
end

if isempty(stimTypes)
    isDesiredStimType = true(1, numEvents);
else
    numStimTypes = numel(stimTypes);
    intersectMatST = zeros(numStimTypes, numEvents);
    for s = 1:numStimTypes
        stimTypeString = regexprep(stimTypes{s}, " ", "_");
        try
            stimTypeVal = obj.info.stimTypes.(stimTypeString);
            intersectMatST(s, :) = ismember(eventStimTypes, stimTypeVal);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No StimType %s found. Please edit config file and recreate object', stimTypeString));
            throw(mv)
        end
    end
    isDesiredStimType = any(intersectMatST, 1);
end

%% Outcomes
if ischar(outcomes)
    outcomes = {outcomes};
end

if isempty(outcomes)
    isDesiredOutcome = true(1, numEvents);
else
    numOutcomes = numel(outcomes);
    intersectMatO = zeros(numOutcomes, numEvents);
    for o = 1:numOutcomes
        outcomeString = regexprep(outcomes{o}, " ", "_");
        try
            outcomeVal = obj.info.outcomes.(outcomeString);
            intersectMatO(o, :) = ismember(eventOutcomes, outcomeVal);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeString));
            throw(mv)
        end
    end
    isDesiredOutcome = any(intersectMatO, 1);
end

%% Trial numbers
if isempty(trials)
    trialIncluded = ones(1, numEvents);
else
    trialIncluded = ismember(trializedEvents, trials);
end

goodTrials = isDesiredTT & isDesiredStimType & isDesiredOutcome & trialIncluded;
