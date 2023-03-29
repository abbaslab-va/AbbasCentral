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

defaultEdges = [-2 2];          % seconds
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
event = a.stateName;
edges = a.edges;
trialType = a.trialType;
outcome = a.outcome;
offset = a.offset;
alignToEnd = a.eos;

bodyAngles = get_body_angle(obj.coordinates);
[firstFrame, firstTrial] = find_first_frame(obj.bpod);
framesByTrial = align_frames_to_trials(obj.bpod, size(obj.coordinates, 1), firstTrial);

% if alignToEnd
%     frameIdx = extract_field_frames_eof()