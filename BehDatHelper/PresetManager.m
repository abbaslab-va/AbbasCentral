classdef PresetManager < handle

% Manages combinations of trialtypes, outcomes, trial numbers, bpod events,
% and neuron combinations like FR-thresholded or user-defined.
    
    properties (SetAccess = public)
        subset          % Indices of neurons for population fcns
        event           % Which event to align data to
        bpod            % Bool toggling which find_event fcn to use
        trialized       % Bool to output each trial in separate cells or all as one vector
        trials          % Indices of which bpod trials to include
        trialType       % Sets of bpod trialTypes
        stimType        % Sets of bpod stimTypes
        outcome         % Sets of bpod outcomes
        delayLength     % Trials with delays within this range
        edges           % Distance from alignment(seconds)
        offset          % Amount to slide the output (seconds)
        binWidth        % Output granularity (ms)
        withinState     % Only return events within certain bpod states
        excludeState    % Opposite behavior from withinState
        priorToState    % Return the last (bpod) event(s) prior to a bpod state
        priorToEvent    % Return the last (bpod) event(s) prior to a bpod event
        afterState      % Return the first event(s) after a bpod state
        afterEvent      % Return the first event(s) after a bpod event
        ignoreRepeats   % If true, afterEvent and priorToEvent ignore duplicate events
        freqLimits      % Edges for calculating frequency-domain props
        panel           % Allows for plotting to app
    end

    methods

        % Constructor needs work
        function [obj, updated] = PresetManager(varargin) 
            % Validation functions
            validPreset = @(x) isempty(x) || isa(x, 'PresetManager');
            validVectorSize = @(x) all(size(x) == [1, 2]);
            validEvent = @(x) isempty(x) || ischar(x) || isstring(x);
            validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
            validTrials = @(x) isempty(x) || isvector(x);
            validNumber = @(x) isnumeric(x) && x > 0;
            validNeurons = @(x) isnumeric(x) && all(x > 0);

            % Parse variable inputs
            p = inputParser;
            p.KeepUnmatched = true;
            addParameter(p, 'subset', [], validNeurons)
            addParameter(p, 'event', 'Trial Start', validEvent)
            addParameter(p, 'bpod', false, @islogical)
            addParameter(p, 'trialized', false, @islogical);
            addParameter(p, 'trials', {}, validTrials);
            addParameter(p, 'trialType', {}, validField);
            addParameter(p, 'stimType', {}, validField);
            addParameter(p, 'outcome', {}, validField);
            addParameter(p, 'delayLength', [], validVectorSize);
            addParameter(p, 'offset', 0, @isnumeric);
            addParameter(p, 'edges', [-2 2], validVectorSize);
            addParameter(p, 'binWidth', 1, validNumber);
            addParameter(p, 'withinState', [], validField)
            addParameter(p, 'excludeState', [], validField)
            addParameter(p, 'priorToState', [], validField)
            addParameter(p, 'priorToEvent', [], validField)
            addParameter(p, 'afterState', [], validField);
            addParameter(p, 'afterEvent', [], validField);
            addParameter(p, 'ignoreRepeats', true, @islogical);
            addParameter(p, 'freqLimits', [1 120], validVectorSize);
            addParameter(p, 'panel', []);
            addParameter(p, 'preset', [], validPreset)
            parse(p, varargin{:});
            a = p.Results;
            
            changedIdx = ~ismember(p.Parameters, p.UsingDefaults);
            updated = p.Parameters(changedIdx);
            % Distribute inputs/default values
            if ~isempty(a.preset)
                obj.copy_and_update(a.preset, p);
            else
                obj.fill(a)
            end
        end
    
        function copy(obj, copyObj)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = copyObj.(currentProp);
            end
        end

        function fill(obj, results)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = results.(currentProp);
            end
        end

        function copy_and_update(obj, copyObj, parser)
            obj.copy(copyObj);
            newParamIdx = ~ismember(parser.Parameters, parser.UsingDefaults);
            updateParams = parser.Parameters(newParamIdx);
            goodParams = cellfun(@(x) ~strcmp(x, 'preset'), updateParams);
            updateParams = updateParams(goodParams);
            for prop = 1:numel(updateParams)
                currentProp = updateParams{prop};
                obj.(currentProp) = parser.Results.(currentProp);
            end
        end
    end
end