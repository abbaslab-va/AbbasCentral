function stateFrames = find_state_frames(obj, stateName, varargin)
 
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
presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addRequired(p, 'stateName', @ischar);
addParameter(p, 'eos', defaultEOS, @islogical);
parse(p, stateName, varargin{:});
stateName = p.Results.stateName;
alignToEnd = p.Results.eos;

% stateEdge determines if frames are found from the end of a state
% backwards by offset (2) or from the start of a state (1)
if alignToEnd
    stateEdge = 2;
else
    stateEdge = 1;
end
goodTrials = obj.bpod.trial_intersection_BpodParser('preset', presets);
[firstFrame, firstTrial] = find_first_frame(obj.bpod.session);
framesByTrial = align_frames_to_trials(obj.bpod.session, size(obj.coordinates, 1), firstTrial);
framesByTrial = framesByTrial(:, goodTrials);
EventCells = obj.bpod.session.RawEvents.Trial;
EventCells = EventCells(goodTrials);
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