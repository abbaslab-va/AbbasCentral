function keywords = hctsa_keywords(obj, varargin)

presets = PresetManager(varargin{:});
[~, eventTrial] = obj.find_event('event', presets.event);

keywords = cell(1, numel(eventTrial));
bpodSess = obj.bpod.session;
allTrialTypes = fields(obj.bpod.config.trialTypes);
allOutcomes = fields(obj.bpod.config.outcomes);

for trial = eventTrial
    trialType = bpodSess.TrialTypes(trial);
    trialOutcome = bpodSess.SessionPerformance(trial);
    matchingTrialType = structfun(@(x) any(ismember(x, trialType)), obj.bpod.config.trialTypes);
    matchingOutcome = structfun(@(x) any(ismember(x, trialOutcome)), obj.bpod.config.outcomes);
    ttKeywords = allTrialTypes(matchingTrialType);
    outcomeKeywords = allOutcomes(matchingOutcome);
    joinedString = join([presets.event; ttKeywords; outcomeKeywords], ',');
    keywords{trial} = joinedString{1};
end