classdef BehDat < handle

% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab. Initially developed to interface bpod behavioral
% sessions with recording data collected from the Cereplex Direct made by
% Blackrock Neurotech, it can be generalized to apply to a wide range of
% data acquisition systems. The core functionality, however, comes from the
% integration with Bpod behavior data collected in boxes made by Sanworks.

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

        state_sankey(obj, varargin)

        event_sankey(obj, varargin)

        timestamps = find_bpod_event(obj, event, varargin)
        
        stateEdges = find_bpod_state(obj, stateName, varargin)

        adjust_vip_trialTypes(obj)

        add_focus_trialTypes(obj)

    %% Spike methods
    
        [timestamps, bpodTrials] = find_event(obj, event, varargin)
        
        spikesByTrial = trialize_spikes(obj, trialStart)

        binnedSpikes = bin_spikes(obj, eventEdges, binSize)

        binnedTrials = bin_neuron(obj, event, neuron, varargin)

        binnedNeurons = bin_all_neurons(obj, event, varargin)

        h = raster(obj, event, neuron, varargin)

        smoothedSpikes = psth(obj, event, neuron, varargin)

        h = mean_population_response(obj, event, varargin)
        
        [zMean, zCells, trialNum] = z_score(obj, event, varargin)

        [corrScore, trialTypes] = xcorr(obj, event, edges)

        plot_xcorr(obj, ref, target, window)

        find_mono(obj)

        plot_mono(obj, varargin)

        G = plot_digraph(obj, trialized, panel)
    
        weightsEx = trialize_mono_excitatory(obj, trialType, alignment, edges, varargin)
        
        weightsIn = trialize_mono_inhibitory(obj, trialType, alignment, edges, varargin)

        sigs = zeta_call(obj, event, varargin) 
        
        hctsa(obj, varargin)
    %% LFP methods

        [pwr, freqs, phase, lfpAll] = cwt_power(obj, event, varargin)

        [ppc_all, spikePhase, ppc_sig]  = ppc(obj, event, varargin)

        filteredLFP = filter_signal(obj, event, varargin)

        ITPC = itpc(obj, event, varargin)

        [lfp_all, chanPhase] = lfp_align(obj, event, varargin)

        %plot_cwt(pwr, channel, panel)    panel is an optional arg

    %% Video methods

        stateFrames = find_state_frames(obj, stateName, varargin)
        
        rotVec = trialize_rotation(obj, stateName, varargin)
        
        %[f, h] = rotation_surf(rotVec, panel)

        get_e3v_frame_times(obj, bncData)
        
    %% Additional methods

        noiseRemoved = remove_noisy_periods(obj, rawData, event, varargin)

        bpodOffset = samplingDiff(obj)

        goodTrials = trial_intersection(obj, trializedEvents, outcomes, trialTypes, trials)

    end
end