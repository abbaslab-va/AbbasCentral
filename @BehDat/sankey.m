function sankey(obj, varargin)

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

session = obj.bpod;
defaultInput = session.RawData.OriginalStateNamesByNumber{1};   % all input states
defaultOutput = defaultInput;                                   % all output states
validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);

p = parse_BehDat('outcome', 'trialType', 'trials');
addParameter(p, 'inputStates', defaultInput, validField);
addParameter(p, 'outputStates', defaultOutput, validField);
parse(p, varargin{:});
a = p.Results;
eventTrialTypes = session.TrialTypes;
eventOutcomes = session.SessionPerformance;

goodTT = true(1, session.nTrials);
goodOutcomes = true(1, session.nTrials);

if ~isempty(a.trialType)
    trialTypeField = regexprep(a.trialType, " ", "_");
    try
        trialTypes = obj.info.trialTypes.(trialTypeField);
        goodTT = ismember(eventTrialTypes, trialTypes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeField));
        throw(mv)
    end
end

if ~isempty(a.outcome)
    outcomeField = regexprep(a.outcome, " ", "_");
    try
        outcomes = obj.info.outcomes.(outcomeField);
        goodOutcomes = ismember(eventOutcomes, outcomes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
        throw(mv)
    end
end
trialsToInclude = find(goodTT & goodOutcomes);
startState = cell(0);
endState = cell(0);
for trial = trialsToInclude
    stateNames = session.RawData.OriginalStateNamesByNumber{trial};
    trialEvents = session.RawData.OriginalStateData{trial};
    numStates = numel(trialEvents);
    for state = 1:numStates-1
        if any(strcmp(a.inputStates, stateNames{trialEvents(state)})) & any(strcmp(a.outputStates, stateNames{trialEvents(state+1)}))
            startState{end+1} = stateNames{trialEvents(state)};
            endState{end+1} = stateNames{trialEvents(state+1)};
        end
    end
end

startState = categorical(startState');
endState = categorical(endState');
t = table(startState, endState, 'VariableNames', ["Start", "End"]);

options.color_map = 'parula';      
options.flow_transparency = 0.2;   % opacity of the flow paths
options.bar_width = 120;            % width of the category blocks
options.show_perc = false;          % show percentage over the blocks
options.text_color = [0 0 0];      % text color for the percentages
options.show_layer_labels = true;  % show layer names under the chart
options.show_cat_labels = true;   % show categories over the blocks.
options.show_legend = false;    

plotSankeyFlowChart(t, options);

