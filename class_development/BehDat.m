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
        
        %Requires bpod_performance from Abbas-WM repository
        function [numTT, numCorrect] = outcomes(obj, val)
            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
        end
        %bins spikes into trialized cell arrays
        function spikes = trialize_spikes(event, duration)
            
        end

        function h = plot_outcome(obj, val)

            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
            h = figure;
            bar(h, numCorrect./numTT)
%             bar_and_error(numCorrect./numTT)      Bar and error fcn not
%             currently working for this type of data. Cannot calculate SEM
%             using one dimensional data
        end
    end
end