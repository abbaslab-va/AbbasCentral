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
        outcome         % Sets of bpod outcomes
        edges           % Distance from alignment(seconds)
        offset          % Amount to slide the output (seconds)
        binWidth        % Output granularity (ms)
        withinState     % Only return events within certain bpod states
        excludeEventsByState    % Opposite behavior from withinState (should get renamed excludeState)
        priorToState    % Return the last (bpod) event prior to a bpod state
        priorToEvent    % Return the last (bpod) event prior to a bpod event
        freqLimits      % Edges for calculating frequency-domain props
        panel           % Allows for plotting to app
    end

    methods

        % Constructor needs work
        function obj = PresetManager(varargin) 
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
            addParameter(p, 'outcome', {}, validField);
            addParameter(p, 'offset', 0, @isnumeric);
            addParameter(p, 'edges', [-2 2], validVectorSize);
            addParameter(p, 'binWidth', 1, validNumber);
            addParameter(p, 'withinState', [], validField)
            addParameter(p, 'excludeEventsByState', [], validField)
            addParameter(p, 'priorToState', [], validField)
            addParameter(p, 'priorToEvent', [], validField)
            addParameter(p, 'freqLimits', [1 120], validVectorSize);
            addParameter(p, 'panel', []);
            addParameter(p, 'preset', [], validPreset)  % Overwrites all other presets
            parse(p, varargin{:});
            a = p.Results;

            % Distribute inputs/default values
            obj.subset = a.subset;
            obj.event = a.event;
            obj.bpod = a.bpod;
            obj.trialized = a.trialized;
            obj.trials = a.trials;
            obj.trialType = a.trialType;
            obj.outcome = a.outcome;
            obj.offset = a.offset;
            obj.edges = a.edges;
            obj.binWidth = a.binWidth;
            obj.withinState = a.withinState;
            obj.excludeEventsByState = a.excludeEventsByState;
            obj.priorToState = a.priorToState;
            obj.priorToEvent = a.priorToEvent;
            obj.freqLimits = a.freqLimits;
            obj.panel = a.panel;
            if ~isempty(a.preset)
                copy_presets(obj, a.preset);
            end
        end

        function copy_presets(obj, copyObj)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = copyObj.(currentProp);
            end
        end
    end
end