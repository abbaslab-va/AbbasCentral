function [eventTimes, eventNames] = event_times(obj, varargin)
% 
% OUTPUT:
%     eventTimes - a 1xT cell array of event times from a BpodSession, where T is the number of trials
% INPUT: optional name/value pairs
%     'event' - a named Bpod event ('Port1In', regular expressions ('Port[123]Out'))
%     'withinState' - Only return events within certain bpod states
%     'excludeState' - Opposite behavior from withinState
%     'priorToState' - Return the last (bpod) event(s) prior to a bpod state
%     'afterState' - Return the first event(s) after a bpod state
%     'priorToEvent' - Return the last (bpod) event(s) prior to a bpod event
%     'afterEvent' - Return the first event(s) after a bpod event   

presets = PresetManager(varargin{:});

p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'ignoreRepeats', false, @islogical)
% This param should be used when your event needs to not be the first or
% last event in a trial, i.e. there was a recorded event on either side of
% it.
addParameter(p, 'isBracketed', false, @islogical)   % makes sure everthing is paired
addParameter(p, 'returnPrev', false, @islogical)    % returns previous matching event type (input in  gives previous in)
addParameter(p, 'returnNext', false, @islogical)    % returns next matching event type (input in  gives next in)
addParameter(p, 'returnOut', false, @islogical)     % returns next unmatched event type (input in  gives next out)
parse(p, varargin{:});
ignoreRepeats = p.Results.ignoreRepeats;
isBracketed = p.Results.isBracketed;
returnPrev = p.Results.returnPrev;
returnNext = p.Results.returnNext;
returnOut = p.Results.returnOut;
if returnPrev && returnNext
    throw(MException('BehDat:badArgs', 'returnPrev and returnNext cannot both be set to true'))
elseif returnPrev || returnNext
    ignoreRepeats = true;
    isBracketed = true;
end
rawEvents = obj.session.RawEvents.Trial;
rawData = obj.session.RawData;
% Identify trials with the event of interest
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), presets.event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);
eventTimes = cellfun(@(x) cat(2, x{:}), eventTimes, 'uni', 0);


[eventNames, eventLogical] = cellfun(@(x) map_bpod_events(x), rawData.OriginalEventData, 'uni', 0);
sortedTimes = cellfun(@(x, y) x(y), rawData.OriginalEventTimestamps, eventLogical, 'uni', 0);
currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, eventTimes, 'uni', 0);
% Remove the first and last pair of currentEventTimes so that all times are
% guaranteed to have an previous and next event
if isBracketed
    for t = 1:numel(currentEventTimes)
        if ~isempty(currentEventTimes{t})
            currentEventTimes{t}([1, 2, end-1, end]) = false;
        else
            currentEventTimes{t}=[];
        end 
    end    
    eventTimes = cellfun(@(x, y) x(y), sortedTimes, currentEventTimes, 'uni', 0);
end

eventInds = cellfun(@(x) find(x), currentEventTimes, 'uni', 0);
if returnNext
    eventsElapsed = cellfun(@(x) [diff(x) 0], eventInds, 'uni', 0);
else
    eventsElapsed = cellfun(@(x) [0 diff(x)], eventInds, 'uni', 0);
end
% ignoreRepeats flag will return only the first event in a series of
% repeated events. could change contents of eventsElapsed cellfun to read
% [diff(x) 0] to only return the last event instead
if ignoreRepeats
    % Check for diff == 2 because that indicates a consecutive event, since
    % a port in will always be followed by a port out and vice versa
    eventsToKeep = cellfun(@(x) x ~= 2, eventsElapsed, 'uni', 0);
    trialsToRepair = cellfun(@(x) numel(x) == 0, eventTimes);
    [eventsToKeep{trialsToRepair}] = deal([]);
    eventTimes = cellfun(@(x, y) x(y), eventTimes, eventsToKeep, 'uni', 0);
end


eventNames = cellfun(@(x, y) x(y), eventNames, currentEventTimes, 'uni', 0);
intersectMat = cell([size(eventTimes), 6]);


[intersectMat(:, :, 1)] = obj.event_within_state('eventTimes', eventTimes, 'stateName', presets.withinState);
[intersectMat(:, :, 2)] = obj.event_exclude_state('eventTimes', eventTimes, 'stateName', presets.excludeState);
[intersectMat(:, :, 3)] = obj.event_prior_to_state('eventTimes', eventTimes, 'stateName', presets.priorToState);
[intersectMat(:, :, 4)] = obj.event_after_state('eventTimes', eventTimes, 'stateName', presets.afterState);
[intersectMat(:, :, 5)] = obj.event_prior_to_event('eventTimes', eventTimes, 'eventName', presets.priorToEvent);
[intersectMat(:, :, 6)] = obj.event_after_event('eventTimes', eventTimes, 'eventName', presets.afterEvent);
intersectMat = squeeze(intersectMat)';

intersectMat = cellfun(@(x) vertcat(x{:}), num2cell(intersectMat, 1), 'uni', 0);
goodEvents = cellfun(@(x) all(x, 1), intersectMat, 'uni', 0);
eventTimes = cellfun(@(x, y) x(y), eventTimes, goodEvents, 'uni', 0);

if returnNext
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, eventTimes, 'uni', 0);
    currentEventTimes = cellfun(@(x) circshift(x, +2), currentEventTimes, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(y), sortedTimes, currentEventTimes, 'uni', 0);
elseif returnPrev
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, eventTimes, 'uni', 0);
    currentEventTimes = cellfun(@(x) circshift(x, -2), currentEventTimes, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(y), sortedTimes, currentEventTimes, 'uni', 0);
elseif returnOut
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, eventTimes, 'uni', 0);
    currentEventTimes = cellfun(@(x) circshift(x, +1), currentEventTimes, 'uni', 0);
    eventTimes = cellfun(@(x, y) x(y), sortedTimes, currentEventTimes, 'uni', 0);
end


goodTrials = obj.trial_intersection_BpodParser('preset', presets);
eventTimes = eventTimes(goodTrials);
eventNames = eventNames(goodTrials);