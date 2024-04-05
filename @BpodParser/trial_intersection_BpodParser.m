function goodTrials = trial_intersection_BpodParser(obj, varargin)

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
presets = PresetManager(varargin{:});

bpodStruct = obj.session;
numTrials = bpodStruct.nTrials;
eventTrialTypes = bpodStruct.TrialTypes;
eventOutcomes = bpodStruct.SessionPerformance;

if isfield(bpodStruct, 'StimTypes')
    eventStimTypes = bpodStruct.StimTypes;
    stimTypes = presets.stimType;
else
    stimTypes = [];
end
    
trialTypes = presets.trialType;
outcomes = presets.outcome;
trials = presets.trials;
delayLength = presets.delayLength;


%% Trial Types
if ischar(trialTypes)
    trialTypes = {trialTypes};
end

if isempty(trialTypes) || strcmp(trialTypes, 'All')
    isDesiredTT = true(1, numTrials);
else
    numTT = numel(trialTypes);
    intersectMatTT = zeros(numTT, numTrials);
    for tt = 1:numTT
        trialTypeString = regexprep(trialTypes{tt}, " ", "_");
        try
            trialTypeVal = obj.config.trialTypes.(trialTypeString);
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

if isempty(stimTypes) || strcmp(stimTypes, 'All')
    isDesiredStimType = true(1, numTrials);
else
    numStimTypes = numel(stimTypes);
    intersectMatST = zeros(numStimTypes, numTrials);
    for s = 1:numStimTypes
        stimTypeString = regexprep(stimTypes{s}, " ", "_");
        try
            stimTypeVal = obj.config.stimTypes.(stimTypeString);
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

if isempty(outcomes) || strcmp(outcomes, 'All')
    isDesiredOutcome = true(1, numTrials);
else
    numOutcomes = numel(outcomes);
    intersectMatO = zeros(numOutcomes, numTrials);
    for o = 1:numOutcomes
        outcomeString = regexprep(outcomes{o}, " ", "_");
        try
            outcomeVal = obj.config.outcomes.(outcomeString);
            intersectMatO(o, :) = ismember(eventOutcomes, outcomeVal);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeString));
            throw(mv)
        end
    end
    isDesiredOutcome = any(intersectMatO, 1);
end

%% Delay Length
if isempty(delayLength) || strcmp(delayLength, 'All')
    isDesiredDelay = ones(1, numTrials);
else
    try
        delayTimes = extractfield(bpodStruct.GUI, 'DelayHoldTime');
        isDesiredDelay = discretize(delayTimes, delayLength);
        isDesiredDelay = ~isnan(isDesiredDelay);
    end
end

%% Trial numbers
if isempty(trials)
    trialIncluded = ones(1, numTrials);
else
    trialIncluded = ismember(1:bpodStruct.nTrials, trials);
end

goodTrials = isDesiredTT & isDesiredStimType & isDesiredOutcome & isDesiredDelay & trialIncluded;
