function stateEdges = state_times(obj, stateName, varargin)

% OUTPUT:
%     stateEdges - a 1xN cell array of state edges where N is the number of trials.
% 
% INPUTS:
%     stateName - a name of a bpod state to find edges for

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'returnStart', false, @islogical)
addParameter(p, 'returnEnd', false, @islogical)
parse(p, varargin{:})
returnStart = p.Results.returnStart;
returnEnd = p.Results.returnEnd;

% eventIdx refers to which state edge to return
if (returnStart && returnEnd) || (~returnStart && ~returnEnd)
    eventIdx = [1, 2];
elseif returnStart
    eventIdx = 1;
elseif returnEnd
    eventIdx = 2;
end

% Trialized bpod information
rawEvents = obj.session.RawEvents.Trial;
fieldNames = cellfun(@(x) fields(x.States), rawEvents, 'uni', 0);

% Logical indicating position in ordered state cells
fieldsToIndex = cellfun(@(x) strcmp(x, stateName), fieldNames, 'uni', 0);
trialCells = cellfun(@(x) struct2cell(x.States), rawEvents, 'uni', 0);

% Index and concatenate
stateTimesBpod = cellfun(@(x, y) x(y), trialCells, fieldsToIndex, 'uni', 0);
stateTimes = cellfun(@(x) cat(1, x{:}), stateTimesBpod, 'uni', 0);
stateEdges = cellfun(@(x) x(all(~isnan(x), 2), :), stateTimes, 'uni', 0);
stateEdges = cellfun(@(x) num2cell(x, 2), stateEdges, 'uni', 0);
goodTrials = obj.trial_intersection_BpodParser('preset', presets);
stateEdges = stateEdges(goodTrials);
stateEdges = cellfun(@(x) cellfun(@(y) y(eventIdx), x, 'uni', 0), stateEdges, 'uni', 0);
if ~presets.trialized
    stateEdges = cat(1, stateEdges{:});
end
