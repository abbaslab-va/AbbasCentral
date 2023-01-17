% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab.

classdef BehDat
    properties
        baud
        frames
        bpod
        timestamps
    end

    methods
        %Constructor with two mandatory inputs
        function obj = BehDat(b, f, beh, ts)
            if nargin == 4
                obj.baud = b;
                obj.frames = f;
                obj.bpod = beh;
                obj.timestamps = ts;
            end
        end
        
        function import_behavior(obj, bpodSession)
            if nargin == 2
                obj.bpod = bpodSession;
            end
        end
        %Requires bpod_performance from Abbas-WM repository
        function [numTT, numCorrect] = outcomes(obj, val)
            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
        end

        function plot_outcome(obj, val)

            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);

            bar_and_error(numCorrect./numTT)
        end
    end
end