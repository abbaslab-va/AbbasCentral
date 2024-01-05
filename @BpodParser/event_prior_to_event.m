function goodTimes = event_prior_to_event(obj, varargin)

validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = inputParser;
addParameter(p, 'eventName', [], validField);
addParameter(p, 'eventTimes', [], validField);
parse(p, varargin{:})
a = p.Results;
if isempty(a.eventName)
    goodTimes = cellfun(@(x) ones(size(x)), a.eventTimes, 'uni', 0);
    return
end

rawData = obj.session.RawData;

[sortedNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData.OriginalEventData, 'uni', 0);
sortedTimes = cellfun(@(x, y) x(y), rawData.OriginalEventTimestamps, eventInds, 'uni', 0); 
% Event times are now organized chronologically in sortedTimes, with a
% corresponding cell array for the names of the events
currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, a.eventTimes, 'uni', 0);
priorToEventTimes = cellfun(@(x) regexp(x, a.eventName), sortedNames, 'uni', 0);
priorToEventTimes = cellfun(@(x) cellfun(@(y) ~isempty(y), x), priorToEventTimes, 'uni', 0);
% Shift priorTo matrix one event to the left, eliminate the last event
% due to circular shifting, and intersect logical matrices
eventPrior = cellfun(@(x) circshift(x, -1), priorToEventTimes, 'uni', 0);
for t = 1:numel(eventPrior)
    try
        eventPrior{t}(end) = false;
    catch
    end
end
timesToKeep = cellfun(@(x, y) x & y, currentEventTimes, eventPrior, 'uni', 0);
goodEventTimes = cellfun(@(x, y) x(y), sortedTimes, timesToKeep, 'uni', 0);

goodTimes = cellfun(@(x, y) ismember(x, y), a.eventTimes, goodEventTimes, 'uni', 0);