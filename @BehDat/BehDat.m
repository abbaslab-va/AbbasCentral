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
        end

    %% Bpod methods
        
        [numTT, numCorrect] = outcomes(obj, val)

        plot_performance(obj, outcome, panel)

        sankey(obj)

        adjust_vip_trialTypes(obj)

        graceStateTimes = add_focus_trialTypes(obj)

    %% Spike methods
    
        timestamps = find_event(obj, event, varargin)
        
        spikesByTrial = trialize_spikes(obj, trialStart)

        binnedSpikes = bin_spikes(obj, eventEdges, binSize)

        binnedTrials = bin_neuron(obj, event, neuron, varargin)

        raster(obj, event, neuron, varargin)

        psth(obj, event, neuron, varargin)
        
        [zMean, zCells, trialNum] = z_score(obj, baseline, bWindow, event, eWindow, binWidth)

        [corrScore, trialTypes] = xcorr(obj, event, edges)

        plot_xcorr(obj, ref, target, window)

        maxVals = mono_corr_max(obj, corrCells, region1, region2)

        find_mono(obj)

        plot_mono(obj, varargin)

        G = plot_digraph(obj, trialized, panel)
    
        weightsEx = trialize_mono_excitatory(obj, trialType, alignment, edges, varargin)
        
        weightsIn = trialize_mono_inhibitory(obj, trialType, outcome)
        
    %% LFP methods

        [pwr, freqs, phase] = cwt_power(obj, event, varargin)

        [ppc, spikePhase] = ppc(obj, event, varargin)

        %plot_cwt(pwr, channel, panel)    panel is an optional arg

    %% Video methods

        
    end
end