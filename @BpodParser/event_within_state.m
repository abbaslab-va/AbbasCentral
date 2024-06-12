function goodTimes = event_within_state(obj, varargin)
% 
% This method is not intended for use outside the BpodParser class: it is an
% internal method for the withinState param in event_times.
% 
% OUTPUT: 
%     goodTimes - a 1xT cell array of 1xE logical vectors, where T is the number of trials
%     in the session and E is the number of events in a given trial. Ones indicate
%     times that are within the inputted stateName.
% INPUT:
%     stateName - a named Bpod State in the State Machine.
%     eventTimes - the times from a call to event_times

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




if ischar(a.stateName) || isstring(a.stateName)
    stateTimes = obj.state_times(a.stateName, 'trialized', true);
elseif iscell(a.stateName)
    stateTimeCell = cellfun(@(x) obj.state_times(x, 'trialized', true), a.stateName, 'uni', 0);
    stateTimeCell = cat(1, stateTimeCell{:});
    eventIdx = num2cell(1:numel(a.eventTimes));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:,x}),  eventIdx, 'uni', 0);
end

% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
trialContainsState = cellfun(@(x) ~isempty(x), stateTimes);
trialContainsEvent = cellfun(@(x) ~isempty(x), a.eventTimes);
trialsToIgnore = ~trialContainsState | ~trialContainsEvent;
trialsToCheck = ~trialsToIgnore;
eventCell = cell(size(trialsToCheck));
eventCell(trialsToIgnore) = cellfun(@(x) false(1, numel(x)), a.eventTimes(trialsToIgnore), 'uni', 0);
goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y,'uni',0), a.eventTimes(trialsToCheck), stateTimes(trialsToCheck), 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventCell(trialsToCheck) = includeTimes;

goodTimes = eventCell;
