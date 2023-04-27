function stateFrames = find_bpod_state(obj, stateName, varargin)
 
% OUTPUT:
%     stateFrames - a 1xN vector of frame times where N is the number of trials.
%     firstFrame - the bpod timing for the first frame of video
% 
% INPUTS:
%     stateName - a name of a bpod state to align to
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'eos' - a boolean that if true, aligns to the end of a state rather than the start

defaultEOS = false;

p = parse_BehDat('offset', 'outcome', 'trialType', 'trials');
addRequired(p, 'stateName', @ischar);
addParameter(p, 'eos', defaultEOS, @islogical);

parse(p, stateName, varargin{:});
a = p.Results;
stateName = a.stateName;
trialType = a.trialType;
outcome = a.outcome;
offset = a.offset;
alignToEnd = a.eos;
rawEvents = obj.bpod.RawEvents.Trial;

% stateEdge determines if frames are found from the end of a state
% backwards by offset (2) or from the start of a state (1)
if alignToEnd
    stateEdge = 2;
else
    stateEdge = 1;
end

correctTrialType = true(1, obj.bpod.nTrials);
correctOutcome = true(1, obj.bpod.nTrials);
if ~isempty(trialType)
    ttToIndex = obj.info.trialTypes.(trialType);
    correctTrialType = obj.bpod.TrialTypes == ttToIndex;
end
if ~isempty(outcome)
    outcomeToIndex = obj.info.outcomes.(outcome);
    correctOutcome = obj.bpod.SessionPerformance == outcomeToIndex;
end
trialsIntersect = correctTrialType & correctOutcome;

trialStartTimes = obj.find_event('Trial Start');
fieldNames = cellfun(@(x) fields(x.States), rawEvents, 'uni', 0);






[firstFrame, firstTrial] = find_first_frame(obj.bpod);
framesByTrial = align_frames_to_trials(obj.bpod, size(obj.coordinates, 1), firstTrial);
framesByTrial = framesByTrial(:, trialsIntersect);
EventCells = obj.bpod.RawEvents.Trial;
EventCells = EventCells(trialsIntersect);
stateFrames = zeros(1, numel(EventCells));
for trialno = 1:numel(EventCells)
    trialStates = EventCells{trialno}.States;
    if isfield(trialStates,stateName) && ~isempty(framesByTrial{1, trialno})
        delayReward = trialStates.(stateName)(end, stateEdge);
        keyFrames = intersect(find(framesByTrial{1, trialno}<delayReward+.02), find(framesByTrial{1, trialno}>delayReward-.02));
        if keyFrames
            stateFrames(trialno) = framesByTrial{2, trialno}(keyFrames(1));
        end
    end
end
stateFrames(stateFrames == 0) = [];
if offset < 0
    stateFrames = stateFrames + offset;
end