function portInfo = find_port(obj, varargin)

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
addParameter(p, 'proximalEdges', [-.5 .5], validVectorSize)
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

% Check if event occurred within the user-defined edges of the proximal state
proxStateTimes = obj.bpod.state_times(proxState, 'preset', presets);
proxStateTimesAdjusted = proxStateTimes;
trialHasState = cellfun(@(x) ~isempty(x), proxStateTimes);
proxStateEdges = cellfun(@(x) cellfun(@(y) y + proxEdges, x, 'uni', 0), proxStateTimes(trialHasState), 'uni', 0);
proxStateTimesAdjusted(trialHasState) = proxStateEdges;
[proxStateTimesAdjusted{~trialHasState}] = deal({[-2, -1]});
eventProximal = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), proxStateTimesAdjusted, allEventTimes, 'uni', 0);
eventProximal = cellfun(@(x) cat(1, x{:}), eventProximal, 'uni', 0);
whichProxState = cellfun(@(x) any(x, 2), eventProximal, 'uni', 0);
proxStateStart = cellfun(@(x, y) x(y), proxStateTimes, whichProxState, 'uni', 0);
proxStateTrials = cellfun(@(x) ~isempty(x), proxStateStart);
proxStateStart = cellfun(@(x) cellfun(@(y) y(1), x), proxStateStart(proxStateTrials), 'uni', 0);
proxStateStart = cat(1, proxStateStart{:})';
eventProximal = cellfun(@(x) any(x, 1), eventProximal, 'uni', 0);
rewardStateTimes = cellfun(@(x) obj.bpod.state_times(x, 'preset', presets), rewardStateNames, 'uni', 0);
noRewardTrials = cellfun(@(x) cellfun(@(y) isempty(y), x), rewardStateTimes, 'uni', 0);

% Loop through all reward states
eventRewarded = cell(1, numel(rewardStateNames));
prevEventRewarded = eventRewarded;
nextEventRewarded = eventRewarded;
for r = 1:numel(rewardStateTimes)
    [rewardStateTimes{r}{noRewardTrials{r}}] = deal({[-2, -1]});
    eventRewarded{r} = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), rewardStateTimes{r}, allEventTimes, 'uni', 0);
    eventRewarded{r} = cellfun(@(x) cat(1, x{:}), eventRewarded{r}, 'uni', 0);
    prevEventRewarded{r} = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), rewardStateTimes{r}, prevEventTimes, 'uni', 0);
    prevEventRewarded{r} = cellfun(@(x) cat(1, x{:}), prevEventRewarded{r}, 'uni', 0);
    nextEventRewarded{r} = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), rewardStateTimes{r}, nextEventTimes, 'uni', 0);
    nextEventRewarded{r} = cellfun(@(x) cat(1, x{:}), nextEventRewarded{r}, 'uni', 0);
end

% Some dumb concatenation scheme
eventRewarded = cat(1, eventRewarded{:});
eventRewarded = arrayfun(@(i) vertcat(eventRewarded{:, i}), 1:size(eventRewarded, 2), 'UniformOutput', false);
eventRewarded = cellfun(@(x) any(x, 1), eventRewarded, 'uni', 0);
prevEventRewarded = cat(1, prevEventRewarded{:});
prevEventRewarded = arrayfun(@(i) vertcat(prevEventRewarded{:, i}), 1:size(prevEventRewarded, 2), 'UniformOutput', false);
prevEventRewarded = cellfun(@(x) any(x, 1), prevEventRewarded, 'uni', 0);
nextEventRewarded = cat(1, nextEventRewarded{:});
nextEventRewarded = arrayfun(@(i) vertcat(nextEventRewarded{:, i}), 1:size(nextEventRewarded, 2), 'UniformOutput', false);
nextEventRewarded = cellfun(@(x) any(x, 1), nextEventRewarded, 'uni', 0);

% Convert to blackrock sampling rate
allEventTimesBR = obj.bpod_to_blackrock(allEventTimes, presets);
prevEventTimes = obj.bpod_to_blackrock(prevEventTimes, presets);
nextEventTimes = obj.bpod_to_blackrock(nextEventTimes, presets);

% Concatenate all outputs
allEventTimes = cat(2, allEventTimes{:});
allEventTimesBR = cat(2, allEventTimesBR{:});
eventRewarded = cat(2, eventRewarded{:});
prevEventTimes = cat(2, prevEventTimes{:});
prevEventRewarded = cat(2, prevEventRewarded{:});
prevEventID = cat(2, prevEventID{:});
nextEventTimes = cat(2, nextEventTimes{:});
nextEventRewarded = cat(2, nextEventRewarded{:});
nextEventID = cat(2, nextEventID{:});
eventIncluded = cat(2, eventIncluded{:});
eventProximal = cat(2, eventProximal{:});
proxStateStartAll = nan(size(eventProximal));
proxStateStartAll(eventProximal) = proxStateStart - allEventTimes(eventProximal);

% Create output struct
portTimes = struct('previous', prevEventTimes, 'current', allEventTimesBR, 'next', nextEventTimes);
portRewards = struct('previous', prevEventRewarded, 'current', eventRewarded, 'next', nextEventRewarded);
portID = struct('previous', prevEventID, 'next', nextEventID);
proximalInfo = struct('inRange', eventProximal, 'stateStart', proxStateStartAll);
portInfo = struct('times', portTimes, 'reward', portRewards, 'identity', portID, 'proximal', proximalInfo, 'included', eventIncluded);