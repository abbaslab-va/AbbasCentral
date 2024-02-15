function goodTimes = event_prior_to_event(obj, varargin)
% 
% This method is not intended for use outside the BpodParser class: it is an
% internal method for the priorToEvent param in event_times.
% 
% OUTPUT: 
%     goodTimes - a 1xT cell array of 1xE logical vectors, where T is the number of trials
%     in the session and E is the number of events in a given trial. Ones indicate
%     times that occur prior to the inputted eventName.
% INPUT:
%     eventName - a named Bpod event
%     eventTimes - the times from a call to event_times

validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = inputParser;
addParameter(p, 'eventName', [], validField);
addParameter(p, 'eventTimes', [], validField);
parse(p, varargin{:})
a = p.Results;
if isempty(a.eventName)
    goodTimes = cellfun(@(x) true(size(x)), a.eventTimes, 'uni', 0);
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