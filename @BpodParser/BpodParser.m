classdef BpodParser < handle

% This class provides a flexible interface to interact with and extract
% data from Bpod SessionData.

    properties
        session
    end

    methods (Access = public)

        % Constructor
        function obj = BpodParser(bpodSession)
            if exist("bpodSession", 'var')
                obj.session = bpodSession;
            end
        end

        function copy(obj, copyObj)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                obj.(currentProp) = copyObj.(currentProp);
            end
        end
        
        %%% Event Methods
        
        eventTimes = event_times(obj, varargin)

        frameTimes = e3v_bpod_sync(obj, varargin)
        
        %%% State Methods

        stateEdges = state_times(obj, varargin)

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
