% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab.

classdef BehDat
    properties
        name
        baud
        frames
        spikes
        lfp
        waveforms
        timestamps
        bpod
    end

    methods
        function obj = BehDat(n, b, f, s, l, w, ts, beh)
            if nargin == 8
                obj.name = n;
                obj.baud = b;
                obj.frames = f;
                obj.spikes = s;
                obj.lfp = l;
                obj.waveforms = w;
                obj.timestamps = ts;
                obj.bpod = beh;
            end
        end
    %% Functions for Bpod sessions
        function [numTT, numCorrect] = outcomes(obj, val)
            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
        end

        function [f, b, e] = plot_outcome(obj, val, shapeVec)
            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
            if ~exist('shapeVec', 'var')
                shapeVec = numel(numTT);
            end
            [f, b, e] = bar_and_error(numCorrect./numTT, shapeVec);
        end

        function sankey(obj)
            bpod_sankey(obj.bpod)
        end
    %% Functions for spikes
        function sp = trialize_spikes(obj, event, duration)
            eventString = strcat('x_', event);
            try
                timestamp = obj.timestamps.keys.(eventString);
            catch
                mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', event));
                throw(mv)
            end
            if ~exist('duration', 'var')
                duration = 1;   %seconds
            end
        end
    end
end