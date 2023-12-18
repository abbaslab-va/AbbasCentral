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

        eventTimes = event_times(obj, varargin)

        frameTimes = e3v_bpod_sync(obj, varargin)

        %% State Methods

        stateEdges = state_times(obj, varargin)

    end
end
