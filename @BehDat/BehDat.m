% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab.

classdef BehDat < handle
    properties
        info
        spikes
        lfp
        waveforms
        timestamps
        bpod
        coordinates
    end

    methods
        %Constructor
        function obj = BehDat(i, s, l, w, ts, beh, c)
            if nargin == 7
                obj.info = i;
                obj.spikes = s;
                obj.lfp = l;
                obj.waveforms = w;
                obj.timestamps = ts;
                obj.bpod = beh;
                obj.coordinates = c;
            end

            if isfield(obj.spikes, 'times') && ~isfield(obj.spikes, 'trialized')
                try
                    spikesByTrial = trialize_spikes(obj, 'Trial_Start');
                    [obj.spikes.trialized] = deal(spikesByTrial{:});
                catch
                    warning("Unable to generate trialized spike cells." + ...
                        "Please ensure your config file has a timestamp named Trial Start")
                end
            end
        end

    %% Bpod methods
        
        [numTT, numCorrect] = outcomes(obj, val)

        [f, b, e] = plot_outcome(obj, val, shapeVec)

        sankey(obj)

    %% Spike methods
    
        timestamps = find_event(obj, event)
        
        spikesByTrial = trialize_spikes(obj, trialStart)

        binnedSpikes = bin_spikes(obj, eventEdges, binSize)

        binnedTrials = bin_neuron(obj, event, edges, neuron, binSize)

        raster(obj, event, edges, neuron)
        
        [zMean, zCells, trialNum] = z_score(obj, baseline, bWindow, event, eWindow, binWidth)

        [corrScore, trialTypes] = xcorr(obj, event, edges)

        maxVals = mono_corr_max(obj, corrCells, region1, region2)

        find_mono(obj)

        plot_mono(obj)


    %% LFP methods

        [pwr, phase, freqs] = cwt_power(obj, event, edges, freqLimits)

    %% Video methods

        
    end
end