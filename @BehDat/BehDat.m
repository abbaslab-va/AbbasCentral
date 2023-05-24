% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab.

classdef BehDat < handle
    properties
        info
        spikes
        timestamps
        bpod
        coordinates
    end

    methods
        %Constructor
        function obj = BehDat(i, s, ts, beh, c)
            if nargin == 5
                obj.info = i;
                obj.spikes = s;
                obj.timestamps = ts;
                obj.bpod = beh;
                obj.coordinates = c;
            end
        end

    %% Bpod methods
        
        [numTT, numCorrect] = outcomes(obj, val)

        plot_performance(obj, outcome, panel)

        sankey(obj, varargin)

        timestamps = find_bpod_event(obj, event, varargin)
        
        stateEdges = find_bpod_state(obj, stateName, varargin)

        adjust_vip_trialTypes(obj)

        add_focus_trialTypes(obj)

    %% Spike methods
    
        timestamps = find_event(obj, event, varargin)
        
        spikesByTrial = trialize_spikes(obj, trialStart)

        binnedSpikes = bin_spikes(obj, eventEdges, binSize)

        binnedTrials = bin_neuron(obj, event, neuron, varargin)

        raster(obj, event, neuron, varargin)

        psth(obj, event, neuron, varargin)
        
        [zMean, zCells, trialNum] = z_score(obj, event, varargin)

        [corrScore, trialTypes] = xcorr(obj, event, edges)

        plot_xcorr(obj, ref, target, window)

        find_mono(obj)

        plot_mono(obj, varargin)

        G = plot_digraph(obj, trialized, panel)
    
        weightsEx = trialize_mono_excitatory(obj, trialType, alignment, edges, varargin)
        
        weightsIn = trialize_mono_inhibitory(obj, trialType, alignment, edges, varargin)
        
    %% LFP methods

        [pwr, freqs, phase] = cwt_power(obj, event, varargin)

        [ppc_all, spikePhase, ppc_sig]  = ppc(obj, event, varargin)

        filteredLFP = filter_signal(obj, alignment, freqLimits, varargin)

        ITPC = itpc(obj, event, varargin)

        %plot_cwt(pwr, channel, panel)    panel is an optional arg

    %% Video methods

        stateFrames = find_state_frames(obj, stateName, varargin)
        
        rotVec = trialize_rotation(obj, stateName, varargin)
        
        stateFrames = find_bpod_state_video(obj, stateName, varargin)

    %% Additional methods

        noiseRemoved = remove_noisy_periods(obj, rawData, event, varargin)

        bpodOffset = samplingDiff(obj)

    end
end