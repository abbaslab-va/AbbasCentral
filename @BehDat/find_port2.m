function [portInfo, dMat, edges] = find_port2(obj, varargin)

% This is an updated find_port method that uses the BpodParser
% functionality to find the port times.
% OUTPUT:
%     portInfo - a structure containing current/previous/next port times,
%     as well as port identities, if the port was rewarded, which events
%     were excluded, and which events fall near the proximalState.
% INPUT (name/value pairs):
%     event - the main bpod event
%     trialType/outcome/stimType/trials - a trial subset from config file
%     rewardStates - a cell array full of state names that deliver reward
%     proximalState - a state name to find events near
%     proximalEdges - how far on either side of the proximal state to search
    
% Manage inputs
presets = PresetManager(varargin{:});
validVectorSize = @(x) all(size(x) == [1, 2]);
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'rewardStates', {}, @iscell)
addParameter(p, 'proximalState', [], @ischar)
addParameter(p, 'proximalEdges', [-1 3], validVectorSize)
parse(p, varargin{:});
rewardStateNames = p.Results.rewardStates;
proxState = p.Results.proximalState;
proxEdges = p.Results.proximalEdges;


% Get times for all events as well as the events preceding and succeeding
% them (off by two, so it returns events of the same type (in or out))
allEventTimes = obj.bpod.event_times('preset', presets, 'ignoreRepeats', true, 'isBracketed', true);
allEventTimesUnadjusted = obj.bpod.event_times('preset', presets);
eventIncluded = cellfun(@(x, y) ismember(x, y), allEventTimesUnadjusted, allEventTimes, 'uni', 0);
[nextEventTimes, nextEventNames] = obj.bpod.event_times('preset', presets, 'returnNext', true);
nextEventID = cellfun(@(x) cellfun(@(y) str2double(y(5)), x), nextEventNames, 'uni', 0);
[prevEventTimes, prevEventNames] = obj.bpod.event_times('preset', presets, 'returnPrev', true);
prevEventID = cellfun(@(x) cellfun(@(y) str2double(y(5)), x), prevEventNames, 'uni', 0);
%[outEventTimes, outEventNames] = obj.bpod.event_times('preset', presets, 'returnOut', true);
%outEventID = cellfun(@(x) cellfun(@(y) str2double(y(5)), x), outEventNames, 'uni', 0);
