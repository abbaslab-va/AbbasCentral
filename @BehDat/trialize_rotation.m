function rotVec = trialize_rotation(obj, stateName, varargin)
 
% OUTPUT:
%     rotVec: a 1xN cell array where N is the number of trials. Each cell
%     contains a 1xf vector of angle data where f is the number of frames in the
%     period of interest for each trial.
% 
% INPUTS:
%     stateName - a name of a bpod state to align to
% optional name/value pairs:
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'eos' - a boolean that if true, aligns to the end of a state rather than the start

defaultEdges = [0 1];          % seconds
defaultOffset = 0;              % offset from event in seconds
defaultOutcome = [];            % all outcomes
defaultTrialType = [];          % all TrialTypes
defaultEOS = false;

validVectorSize = @(x) all(size(x) == [1, 2]);
validField = @(x) ischar(x) || isempty(x);
p = inputParser;
addRequired(p, 'stateName', @ischar);
addParameter(p, 'edges', defaultEdges, validVectorSize);
addParameter(p, 'offset', defaultOffset, @isnumeric);
addParameter(p, 'outcome', defaultOutcome, validField);
addParameter(p, 'trialType', defaultTrialType, validField);
addParameter(p, 'eos', defaultEOS, @islogical);
parse(p, stateName, varargin{:});

a = p.Results;
stateName = a.stateName;
edges = floor(a.edges * obj.info.baud);
trialType = a.trialType;
outcome = a.outcome;
offset = a.offset;
alignToEnd = a.eos;

bodyAngles = get_body_angle(obj.coordinates);
[firstFrame, firstTrial] = find_first_frame(obj.bpod);
framesByTrial = align_frames_to_trials(obj.bpod, size(obj.coordinates, 1), firstTrial);
framesBack = edges(1);
framesForward = edges(2);

if alignToEnd || edges(1) < 0
    frameIdx = extract_field_frames_eof(obj.bpod, framesByTrial, framesBack, stateName);
else
    frameIdx = extract_field_frames(obj.bpod, framesByTrial, stateName);
end

% This next block of code is written to specifically interface with video
% files recorded during NMTP_Outer_Training2 behavior. It will align the
% video to the behavior in the event that recording started before the bpod
% behavior was initialized.
firstDelay = obj.bpod.RawEvents.Trial{1, 1}.States.WaitForChoicePoke(1, 1);
firstDelayFrames = floor(firstDelay * 30);
cameraOffset = 0;
%Align videos that were started before the behavior session
if firstTrial == 1 && firstFrame < .1
    framesEarly = delay_from_video(vid);
    cameraOffset = framesEarly - firstDelayFrames;
end

frameIdx = frameIdx + floor(offset*obj.info.baud) + cameraOffset;
frameIdx(frameIdx >= size(obj.coordinates, 1) - framesForward) = [];
frameIdx = num2cell(frameIdx);
rotVec = cellfun(@(x) bodyAngles(x:x+framesForward), frameIdx, 'uni', 0);
rotVec = cellfun(@(x) x - x(1), rotVec, 'uni', 0);
rotVec = cat(2, rotVec{:})';
