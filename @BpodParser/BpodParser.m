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

        eventTimes = trialized_event_times(varargin)

        frameTimes = e3v_bpod_sync(varargin)

        %% State Methods

        stateTimes = trialized_state_times(varargin)

    end
end
