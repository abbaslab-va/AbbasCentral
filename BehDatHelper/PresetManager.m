classdef PresetManager < handle

% Manages combinations of trialtypes, outcomes, trial numbers, bpod events,
% and neuron combinations like FR-thresholded or user-defined.
%
% Possible controls include:
%
% animal          % Which animals to include in ExpManager analyses
% condition       % Intersect sessions with a given experimental condition
% includeSessions % Indices of which sessions to include
% excludeSessions % Indices of which sessions to exclude
% subset          % Indices of neurons for population fcns
% region          % A string matching a region in spike data
% label           % String or cell of strings indicating spike label
% KSLabel         % String or cell of strings with kilosort label
% minFR           % Value specifying minimum firing rate to consider
% maxFR           % Value specifying maximum firing rate to consider
% event           % Which event to align data to
% bpod            % Bool toggling which find_event fcn to use
% trialized       % Bool to output each trial in separate cells or all as one vector
% trials          % Indices of which bpod trials to include
% excludeTrials   % Indices of which bpod trials to exclude
% trialType       % Sets of bpod trialTypes
% stimType        % Sets of bpod stimTypes
% outcome         % Sets of bpod outcomes
% delayLength     % Trials with delays within this range
% trialLength     % Trials within a certain length
% edges           % Distance from alignment(seconds)
% offset          % Amount to slide the output (seconds)
% binWidth        % Output granularity (ms)
% stateInTrial    % Returns true if the trial contains the state
% stateNotInTrial % Returns true if the trial does not contain the state
% withinState     % Only return events within certain bpod states
% excludeState    % Opposite behavior from withinState
% priorToState    % Return the last (bpod) event(s) prior to a bpod state
% priorToEvent    % Return the last (bpod) event(s) prior to a bpod event
% afterState      % Return the first event(s) after a bpod state
% afterEvent      % Return the first event(s) after a bpod event
% ignoreRepeats   % If true, afterEvent and priorToEvent ignore duplicate events
% firstEvent      % Return only the first event per bpod trial
% lastEvent       % Return only the last event per bpod trial
% freqLimits      % Edges for calculating frequency-domain props
% panel           % Allows for plotting to app
    
    properties (SetAccess = public)
        animal          % Which animals to include in ExpManager analyses
        condition       % Intersect sessions with a given experimental condition
        includeSessions % Indices of which sessions to include
        excludeSessions % Indices of which sessions to exclude
        subset          % Indices of neurons for population fcns
        region          % A string matching a region in spike data
        label           % String or cell of strings indicating spike label
        KSLabel         % String or cell of strings with kilosort label
        minFR           % Value specifying minimum firing rate to consider
        maxFR           % Value specifying maximum firing rate to consider
        event           % Which event to align data to
        bpod            % Bool toggling which find_event fcn to use
        trialized       % Bool to output each trial in separate cells or all as one vector
        trials          % Indices of which bpod trials to include
        excludeTrials   % Indices of which bpod trials to exclude
        trialType       % Sets of bpod trialTypes
        stimType        % Sets of bpod stimTypes
        outcome         % Sets of bpod outcomes
        delayLength     % Trials with delays within this range
        trialLength     % Trials within a certain length
        edges           % Distance from alignment(seconds)
        offset          % Amount to slide the output (seconds)
        binWidth        % Output granularity (ms)
        stateInTrial    % Returns true if the trial contains the state
        stateNotInTrial % Returns true if the trial does not contain the state
        withinState     % Only return events within certain bpod states
        excludeState    % Opposite behavior from withinState
        priorToState    % Return the last (bpod) event(s) prior to a bpod state
        priorToEvent    % Return the last (bpod) event(s) prior to a bpod event
        afterState      % Return the first event(s) after a bpod state
        afterEvent      % Return the first event(s) after a bpod event
        ignoreRepeats   % If true, afterEvent and priorToEvent ignore duplicate events
        firstEvent      % Return only the first event per bpod trial
        lastEvent       % Return only the last event per bpod trial
        freqLimits      % Edges for calculating frequency-domain props
        panel           % Allows for plotting to app
    end

    methods

        function [obj, updated] = PresetManager(varargin)   % obj constructor

            % Validation functions
            validPreset = @(x) isempty(x) || isa(x, 'PresetManager');
            validVectorSize = @(x) all(size(x) == [1, 2]);
            validEvent = @(x) isempty(x) || ischar(x) || isstring(x);
            validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
            validIndex = @(x) isempty(x) || isvector(x);
            validNumber = @(x) isnumeric(x) && x > 0;
            validNeurons = @(x) isnumeric(x) && all(x > 0);

            % Parse variable inputs
            p = inputParser;
            p.KeepUnmatched = true;
            addParameter(p, 'animal', [], validField)
            addParameter(p, 'condition', [], validField)
            addParameter(p, 'includeSessions', [], validIndex)
            addParameter(p, 'excludeSessions', [], validIndex)
            addParameter(p, 'subset', [], validNeurons)
            addParameter(p, 'region', [], validField)
            addParameter(p, 'label', [], validField)
            addParameter(p, 'KSLabel', [], validField)
            addParameter(p, 'minFR', [], @isnumeric)
            addParameter(p, 'maxFR', [], @isnumeric)
            addParameter(p, 'event', 'Trial Start', validEvent)
            addParameter(p, 'bpod', false, @islogical)
            addParameter(p, 'trialized', false, @islogical)
            addParameter(p, 'trials', [], validIndex)
            addParameter(p, 'excludeTrials', [], validIndex)
            addParameter(p, 'trialType', {}, validField)
            addParameter(p, 'stimType', {}, validField)
            addParameter(p, 'outcome', {}, validField)
            addParameter(p, 'delayLength', [], validVectorSize)
            addParameter(p, 'trialLength', [], validVectorSize)
            addParameter(p, 'offset', 0, @isnumeric)
            addParameter(p, 'edges', [-2 2], validVectorSize)
            addParameter(p, 'binWidth', 1, validNumber)
            addParameter(p, 'stateInTrial', [], validField)
            addParameter(p, 'stateNotInTrial', [], validField)
            addParameter(p, 'withinState', [], validField)
            addParameter(p, 'excludeState', [], validField)
            addParameter(p, 'priorToState', [], validField)
            addParameter(p, 'priorToEvent', [], validField)
            addParameter(p, 'afterState', [], validField)
            addParameter(p, 'afterEvent', [], validField)
            addParameter(p, 'ignoreRepeats', true, @islogical)
            addParameter(p, 'firstEvent', false, @islogical)
            addParameter(p, 'lastEvent', false, @islogical)
            addParameter(p, 'freqLimits', [1 120], validVectorSize)
            addParameter(p, 'panel', [])
            addParameter(p, 'preset', [], validPreset)
            parse(p, varargin{:});
            
            % Distribute parsed inputs/default values to object
            if isempty(p.Results.preset)
                obj.fill(p.Results)
            else
                obj.copy_and_update(p);
            end

            % Outputs which default vals were updated
            changedIdx = ~ismember(p.Parameters, p.UsingDefaults);
            updated = p.Parameters(changedIdx);
        end
    
        % Makes a basic deep copy of the copyObj
        function copy(obj, copyObj) 
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = copyObj.(currentProp);
            end
        end

        % Fills object with values from parsed inputParser
        function fill(obj, results)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = results.(currentProp);
            end
        end


        % Makes a deep copy of the included presets, then updates the
        % remaining fields with extra user inputs
        function copy_and_update(obj, parser)
            obj.copy(parser.Results.preset);
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