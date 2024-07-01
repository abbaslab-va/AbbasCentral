function state_sankey(obj, varargin)

% This function outputs a sankey plot showing the transitions between bpod
% states. By default, it displays all state transitions from all trial
% types, but users can use name-value pairs to only analyze certain
% combinations of trial types and outcomes, as well as only transitions to
% or from a certain state.
% 
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'inputStates' - a string or cell array of strings of desired input
%     states to visualize
%     'outputStates' - a string or cell array of strings of desired output
%     states to visualize

presets = PresetManager(varargin{:});
session = obj.session;
defaultInput = session.RawData.OriginalStateNamesByNumber{1};   % all input states
defaultOutput = defaultInput;                                   % all output states
validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'inputStates', defaultInput, validField);
addParameter(p, 'outputStates', defaultOutput, validField);
parse(p, varargin{:});
inputStates = p.Results.inputStates;
outputStates = p.Results.outputStates;
if isempty(inputStates)
    inputStates = defaultInput;
end
if isempty(outputStates)
    outputStates = defaultOutput;
end
trialsToInclude = find(obj.trial_intersection_BpodParser('preset', presets));
startState = cell(0);
endState = cell(0);

for trial = trialsToInclude
    stateNames = session.RawData.OriginalStateNamesByNumber{trial};
    trialEvents = session.RawData.OriginalStateData{trial};
    numStates = numel(trialEvents);
    for state = 1:numStates-1
        if any(strcmp(inputStates, stateNames{trialEvents(state)})) && any(strcmp(outputStates, stateNames{trialEvents(state+1)}))
            startState{end+1} = stateNames{trialEvents(state)};
            endState{end+1} = stateNames{trialEvents(state+1)};
        end
    end
end

startState = categorical(startState');
endState = categorical(endState');
t = table(startState, endState, 'VariableNames', ["Start", "End"]);
plot_sankey_diagram(t, presets.panel)