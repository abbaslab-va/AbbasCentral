function stateEdges = state_times(obj, stateName)

% OUTPUT:
%     stateEdges - a 1xN cell array of state edges where N is the number of trials.
% 
% INPUTS:
%     stateName - a name of a bpod state to find edges for in the acquisition system's sampling rate
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers to include



rawEvents = obj.session.RawEvents.Trial;



fieldNames = cellfun(@(x) fields(x.States), rawEvents, 'uni', 0);

fieldsToIndex = cellfun(@(x) regexp(x, stateName), fieldNames, 'uni', 0);
fieldsToIndex = cellfun(@(x) cellfun(@(y) ~isempty(y), x), fieldsToIndex, 'uni', 0);

trialCells = cellfun(@(x) struct2cell(x.States), rawEvents, 'uni', 0);
stateTimesBpod = cellfun(@(x, y) x(y), trialCells, fieldsToIndex, 'uni', 0);
stateTimes = cellfun(@(x) cat(1, x{:}), stateTimesBpod, 'uni', 0);

stateEdges = cellfun(@(x) x(all(~isnan(x), 2), :), stateTimes, 'uni', 0);
stateEdges = cellfun(@(x) num2cell(x, 2), stateEdges, 'uni', 0);
stateEdges = cat(1, stateEdges{:});
