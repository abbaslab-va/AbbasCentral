function goodTimes = event_exclude_state(obj, varargin)

validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = inputParser;
addParameter(p, 'stateName', [], validField);
addParameter(p, 'eventTimes', [], validField);
parse(p, varargin{:})
a = p.Results;
if isempty(a.stateName)
    goodTimes = cellfun(@(x) true(size(x)), a.eventTimes, 'uni', 0);
    return
end



if ischar(a.stateName) || isstring(a.stateName)
    stateTimes = obj.state_times(a.stateName);
elseif iscell(a.stateName)
    stateTimeCell = cellfun(@(x) obj.state_times(x), a.stateName, 'uni', 0);
    stateTimeCell = cat(1, stateTimeCell{:});
    eventIdx = num2cell(1:numel(a.eventTimes));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:,x}),  eventIdx, 'uni', 0);
end

% This double cellfun operates on excludeState which contains a cell for each trial,
% with a cell for each state inside of that.
trialContainsState = cellfun(@(x) ~isempty(x), stateTimes);
trialContainsEvent = cellfun(@(x) ~isempty(x), a.eventTimes);
trialsToIgnore = ~trialContainsState | ~trialContainsEvent;
trialsToCheck = ~trialsToIgnore;
eventCell = cell(size(trialsToCheck));
eventCell(trialsToIgnore) = cellfun(@(x) true(1, numel(x)), a.eventTimes(trialsToIgnore), 'uni', 0);
goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y,'uni',0), a.eventTimes(trialsToCheck), stateTimes(trialsToCheck), 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) all(x, 1), includeTimes, 'uni', 0);
eventCell(trialsToCheck) = includeTimes;

goodTimes = eventCell;