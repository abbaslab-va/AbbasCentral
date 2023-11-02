function rotVec = trialize_rotation(obj, stateName, varargin)
% Trializes rotation in experiments that were recorded using the e3v
% watchtower synchronized to the bpod state machine via bnc ttl.
% 
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
validPreset = @(x) isa(x, 'PresetManager');

validVectorSize = @(x) all(size(x) == [1, 2]);
defaultEdges = [0 1];          % seconds
defaultEOS = false;
p = parse_BehDat('offset', 'outcome', 'trialType');
addRequired(p, 'stateName', @ischar);
addParameter(p, 'edges', defaultEdges, validVectorSize);
addParameter(p, 'eos', defaultEOS, @islogical);
addParameter(p, 'preset', [], validPreset)
parse(p, stateName, varargin{:});

if isempty(p.Results.preset)
    a = p.Results;
else
    a = p.Results.preset;
end

stateName = p.Results.stateName;
edges = floor(a.edges * obj.info.baud);
alignToEnd = p.Results.eos;

bodyAngles = get_body_angle(obj.coordinates);
[firstFrame, firstTrial] = find_first_frame(obj.bpod);
% framesByTrial = align_frames_to_trials(obj.bpod, size(obj.coordinates, 1), firstTrial);
framesBack = edges(1);
framesForward = edges(2);

frameIdx = obj.find_state_frames(stateName, 'offset', framesBack, ...
    'outcome', a.outcome, 'trialType', a.trialType, 'eos', alignToEnd);
% if alignToEnd || edges(1) < 0
%     frameIdx = extract_field_frames_eof(obj.bpod, framesByTrial, framesBack, stateName);
% else
%     frameIdx = extract_field_frames(obj.bpod, framesByTrial, stateName);
% end

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

frameIdx = frameIdx + floor(a.offset*obj.info.baud) + cameraOffset;
frameIdx(frameIdx >= size(obj.coordinates, 1) - framesForward) = [];
frameIdx = num2cell(frameIdx);
rotVec = cellfun(@(x) bodyAngles(x:x+framesForward), frameIdx, 'uni', 0);
rotVec = cellfun(@(x) x - x(1), rotVec, 'uni', 0);
rotVec = cat(2, rotVec{:})';
