classdef BpodParser < handle

% This class provides a flexible interface to interact with and extract
% data from Bpod SessionData.

    properties
        session
    end

    methods

        % Constructor
        function obj = BpodParser(bpodSession)
            obj.session = bpodSession;
        end

        %% Event Methods
        eventTimes = event_times_real(obj, varargin)

        eventTimes = event_times(obj, varargin)

        frameTimes = e3v_bpod_sync(obj, varargin)
        
        goodTimes = event_within_state(obj, varargin)

        goodTimes = event_exclude_state(obj, varargin)

        goodTimes = event_prior_to_state(obj, varargin)

        %% State Methods

        stateEdges = state_times(obj, varargin)

    end
end
