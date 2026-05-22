function stateTimes = state_collection(obj, states, varargin)

% Provides a collection of states to the user using the BpodParser
% state_times method.
% 
% INPUT: 
%     states - a cell array of state names
%     varargin - PresetManager name/value pairs
% OUTPUT:
%     state_times - a 1xS cell array of state times, or a singular concatenated
%     array if the combined flag is set to true

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'combined', false, @islogical)
parse(p, varargin{:});
isCombined = p.Results.combined;
numStates = numel(states);
stateTimes = cell(1, numStates);
for s = 1:numStates
    stateName = states{s};
    stateTimes{s} = obj.state_times(stateName, 'preset', presets, 'trialized', true);
end

if isCombined
    stateCat = cat(1, stateTimes{:});
    numTrials = size(stateCat, 2);
    stateTimes = arrayfun(@(x) cat(1, stateCat{:, x}), 1:numTrials, 'uni', 0);
end
