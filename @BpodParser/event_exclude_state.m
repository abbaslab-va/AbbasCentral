function goodTimes = event_exclude_state(obj, varargin)

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




% Get cell array of all state times to exclude events within
excludeStateTimes = obj.state_times(a.stateName);
% Find those state times that are nan (did not happen in the trial)
nanStates = cellfun(@(x) isnan(x{1}(1)), excludeStateTimes);
% This replaces all the times that were nans with negative state edges
% since that's something that will never happen in a bpod state and
% it's easier than removing those trials
for i = find(nanStates)
    excludeStateTimes{i}{1} = [-2 -1];
end
excludeStateTimes = cellfun(@(x) num2cell(x, 2), excludeStateTimes, 'uni', 0);
timesToRemove = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y, 'uni', 0), a.eventTimes, excludeStateTimes, 'uni', 0);
timesToRemove = cellfun(@(x) cat(1, x{:}), timesToRemove, 'uni', 0);
goodTimes = cellfun(@(x) ~any(x == 1, 1), timesToRemove, 'uni', 0);
% eventTimes = cellfun(@(x, y) x(~y), eventTimes, timesToRemove, 'uni', 0);
