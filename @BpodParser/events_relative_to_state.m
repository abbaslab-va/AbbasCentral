function [eventTimes, eventNames, stateNames] = events_relative_to_state(obj, stateName, varargin)

% This method provides the user with event names, times, and which state
% the event occurred in relative to a bpod state. The edges preset will
% determine the range from the named state within which to search.
% OUTPUT:
%     eventTimes - a trialized list of event times within the specified params
%     eventNames - the corresponding names of the events
%     stateNames - which state the event occurred within

presets = PresetManager(varargin{:});
goodTrials = obj.trial_intersection_BpodParser('preset', presets);
rawEvents = obj.session.RawEvents.Trial(goodTrials);
rawData = obj.session.RawData;

% Find edges around the input state to discretize within. State can occur
% multiple times
stateTimes = obj.state_times(stateName, 'preset', presets, 'returnStart', true, 'trialized', true);
relativeEdges = cellfun(@(x) cellfun(@(y) presets.edges + y, x, 'uni', 0), stateTimes, 'uni', 0);
% Copied from event_times: gets ordered events
[sortedEventNames, eventLogical] = cellfun(@(x) map_bpod_events(x), rawData.OriginalEventData(goodTrials), 'uni', 0);
sortedTimes = cellfun(@(x, y) x(y), rawData.OriginalEventTimestamps(goodTrials), eventLogical, 'uni', 0);
% Discretize ordered events within the state edges
timesWithinEdges = cellfun(@(x, y) cellfun(@(z) ~isnan(discretize(y, z)), x, 'uni', 0), relativeEdges, sortedTimes, 'uni', 0);
timesWithinEdges = cellfun(@(x) any(cat(1, x{:}), 1), timesWithinEdges, 'uni', 0);
eventTimes = cellfun(@(x, y) num2cell(x(y)), sortedTimes, timesWithinEdges, 'uni', 0);
eventNames = cellfun(@(x, y) x(y), sortedEventNames, timesWithinEdges, 'uni', 0);
% Get name of state that event occurred within. If it aligns with a state
% transition, the second state will be chosen
allStateNames = cellfun(@(x) fieldnames(x.States), rawEvents, 'uni', 0);
allStateTimes = cellfun(@(x) struct2cell(x.States), rawEvents, 'uni', 0);
stateOccurred = cellfun(@(x) cellfun(@(y) all(all(~isnan(y))), x), allStateTimes, 'uni', 0);
goodStateNames = cellfun(@(x, y) x(y), allStateNames, stateOccurred, 'uni', 0);
goodStateTimes = cellfun(@(x, y) x(y), allStateTimes, stateOccurred, 'uni', 0);
goodStateTimes = cellfun(@(x) cellfun(@(y) num2cell(y, 2), x, 'uni', 0), goodStateTimes, 'uni', 0);
%Subtract 100 microseconds from the end of every state so events cannot
%exist within two states. First cellfun is for trials, second cellfun is
%for states, third is for occurences of the state
goodStateTimes = cellfun(@(x) cellfun(@(y) ...
    cellfun(@(z) [z(1) z(2) - .00005], ...
    y, 'uni', 0), ...
    x, 'uni', 0), ...
    goodStateTimes, 'uni', 0);
% Discretize good state times 
whichState = cellfun(@(v, w) ...                        %For each trial
    cellfun(@(x) ...                                    %For each event in a trial
        cellfun(@(y) ...                                %For each state time
            any(cellfun(@(z) any(~isnan(discretize(x, z))), y)), ...
        w), ...
    v, 'uni', 0), ...
eventTimes, goodStateTimes, 'uni', 0);

stateNames = cellfun(@(x, y) ...
    cellfun(@(z) y(z), x), ...
whichState, goodStateNames, 'uni', 0);