% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab.

classdef BehDat
    properties
        info
        baud
        frames
        spikes
        lfp
        waveforms
        timestamps
        bpod
    end

    methods
        %Constructor
        function obj = BehDat(i, s, l, w, ts, beh)
            if nargin == 6
                obj.info = i;
                obj.spikes = s;
                obj.lfp = l;
                obj.waveforms = w;
                obj.timestamps = ts;
                obj.bpod = beh;
            end
        end

    %% Bpod methods
        
        [numTT, numCorrect] = outcomes(obj, val)

        [f, b, e] = plot_outcome(obj, val, shapeVec)

        sankey(obj)

    %% Spike methods
    
        timestamps = find_event(obj, event)
        
        binnedSpikes = bin_spikes(obj, eventEdges, binSize)
        
        [zMean, zCells, trialNum] = z_score(obj, baseline, bWindow, event, eWindow, binWidth)

    %% LFP methods

        calculate_power(obj)

    %% Video methods

        
    end
end