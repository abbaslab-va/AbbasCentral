function goodTimes = event_within_state(obj, varargin)

validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = inputParser;
addParameter(p, 'stateName', [], validField);
addParameter(p, 'eventTimes', [], validField);
parse(p, varargin{:})
a = p.Results;
if isempty(a.stateName)
    goodTimes = cellfun(@(x) ones(size(x)), a.eventTimes, 'uni', 0);
    return
end
stateTimes = obj.state_times(a.stateName);



if ischar(a.stateName) || isstring(a.stateName)
    stateTimes = obj.state_times(a.stateName);
elseif iscell(a.stateName)
    stateTimeCell = cellfun(@(x) obj.state_times(x), a.stateName, 'uni', 0);
    eventIdx = num2cell(1:numel(a.eventTimes));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);
end

% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
goodTrials = cellfun(@(x) ~isempty(x), a.eventTimes);
goodTimesAll = cellfun(@(x, y) discretize(x, y), a.eventTimes(goodTrials), stateTimes(goodTrials), 'uni', 0);
% includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventCell = cell(size(goodTrials));
[eventCell{goodTrials}] = deal(includeTimes{:});
% eventTimes = cellfun(@(x, y) x(y), a.eventTimes, eventCell, 'uni', 0);
goodTimes = eventCell;
