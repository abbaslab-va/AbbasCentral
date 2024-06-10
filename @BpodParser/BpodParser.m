classdef BpodParser < handle

% This class provides a flexible interface to interact with and extract
% data from Bpod SessionData.

    properties
        session
        info
        config
    end

    methods (Access = public)

        % Constructor
        function obj = BpodParser(varargin)
            validSession = @(x) isstruct(x) || isempty(x);
            p = inputParser;
            addParameter(p, 'session', struct, validSession)
            addParameter(p, 'info', struct, validSession)
            addParameter(p, 'config', struct, validSession)
            parse(p, varargin{:});
            obj.session = p.Results.session;
            obj.info = p.Results.info;
            obj.config = p.Results.config;
        end

        function copy(obj, copyObj)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = copyObj.(currentProp);
            end
        end

        function totSize = get_size(obj)
            propNames = properties(obj); 
            totSize = 0; 
            for prop=1:length(propNames) 
                currentProperty = getfield(obj, char(propNames(prop))); 
                s = whos('currentProperty'); 
                totSize = totSize + s.bytes; 
            end
        end
        %%% Event Methods
        
        [eventTimes, eventNames] = event_times(obj, varargin)

        event_sankey(obj, varargin)
        
        %%% State Methods

        stateEdges = state_times(obj, stateName, varargin)

        state_sankey(obj, varargin)

        %%% Video Methods

        frameTimes = e3v_bpod_sync(obj, varargin)

        %%% Other

        [numTT, numCorrect] = performance(obj, varargin)

        goodTrials = trial_intersection_BpodParser(obj, varargin)

        adjust_vip_trialTypes_tri(obj)

    end
    
    %% Internal Methods

    methods (Access = private)

        goodTimes = event_within_state(obj, varargin)

        goodTimes = event_exclude_state(obj, varargin)

        goodTimes = event_prior_to_state(obj, varargin)

        goodTimes = event_after_state(obj, varargin)

        goodTimes = event_prior_to_event(obj, varargin)

        goodTimes = event_after_event(obj, varargin)

    end
end
