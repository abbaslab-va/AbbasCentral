function eventTimes = event_times(obj, varargin)
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

rawEvents = obj.session.RawEvents.Trial;

% Identify trials with the event of interest
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), presets.event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);
eventTimes = cellfun(@(x) cat(2, x{:}), eventTimes, 'uni', 0);

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