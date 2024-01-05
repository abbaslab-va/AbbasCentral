function goodTimes = event_after_state(obj, varargin)

selectionOpts = {'nearest', 'all'};
validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validSelection = @(x) ismember(x, selectionOpts);
p = inputParser;
addParameter(p, 'stateName', [], validField);
addParameter(p, 'eventTimes', [], validField);
addParameter(p, 'selectionMode', 'nearest', validSelection);
parse(p, varargin{:})
a = p.Results;
if isempty(a.stateName)
    goodTimes = cellfun(@(x) ones(size(x)), a.eventTimes, 'uni', 0);
    return
end

rawData = obj.session.RawData;

stateNumbers = rawData.OriginalStateData;
stateNames = rawData.OriginalStateNamesByNumber;
sortedStateNames = cellfun(@(x, y) x(y), stateNames, stateNumbers, 'uni', 0);
sortedStateTimes = cellfun(@(x) x(2:end), rawData.OriginalStateTimestamps, 'uni', 0);
[sortedEventNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData.OriginalEventData, 'uni', 0);
sortedEventTimes = cellfun(@(x, y) x(y), rawData.OriginalEventTimestamps, eventInds, 'uni', 0); 
eventAndStateTimes = cellfun(@(x, y) [x y], sortedEventTimes, sortedStateTimes, 'uni', 0);
eventAndStateNames = cellfun(@(x, y) [x y], sortedEventNames, sortedStateNames, 'uni', 0);
[sortedCombinedTimes, sortedCombinedInds] = cellfun(@(x) sort(x), eventAndStateTimes, 'uni', 0);
sortedEventAndStateNames = cellfun(@(x, y) x(y), eventAndStateNames, sortedCombinedInds, 'uni', 0);
currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedCombinedTimes, a.eventTimes, 'uni', 0);
afterStateTimes = cellfun(@(x) strcmp(x, a.stateName), sortedEventAndStateNames, 'uni', 0);
% Shift priorTo matrix one event to the left, eliminate the first event
% due to circular shifting, and intersect logical matrices
eventAfterState = cellfun(@(x) circshift(x, 1), afterStateTimes, 'uni', 0);
for t = 1:numel(eventAfterState)
    eventAfterState{t}(1) = false;
end
goodTimesSorted = cellfun(@(x, y) x & y, currentEventTimes, eventAfterState, 'uni', 0);
goodTimeVals = cellfun(@(x, y) x(y), sortedCombinedTimes, goodTimesSorted, 'uni', 0);
goodTimes = cellfun(@(x, y) ismember(x, y), a.eventTimes, goodTimeVals, 'uni', 0);