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
        LabGym
    end

    methods
        %Constructor and copy methods
        function obj = BehDat(i, s, ts, beh, c)
            if nargin == 5
                obj.info = i;
                obj.spikes = s;
                obj.timestamps = ts;
                obj.bpod = beh;
                obj.coordinates = c;
            end
        end
        

        function totSize = get_size(obj) 
            propNames = properties(obj); 
            totSize = 0; 
            for prop=1:length(propNames) 
                currentProperty = getfield(obj, char(props(propNames))); 
                s = whos('currentProperty'); 
                totSize = totSize + s.bytes; 
            end
        end

        function copy(obj, copyObj)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                if isa(copyObj.(currentProp), 'handle')
                    obj.(currentProp) = eval(class(copyObj.(currentProp)));
                    obj.(currentProp).copy(copyObj.(currentProp));
                else
                    obj.(currentProp) = copyObj.(currentProp);
                end
            end
        end
    %% Bpod methods
        
        [numTT, numCorrect] = outcomes(obj, varargin)

        figH = plot_performance(obj, outcome, varargin)

        state_sankey(obj, varargin)

        event_sankey(obj, varargin)
        
        stateEdges = find_bpod_state(obj, stateName, varargin)

        adjust_vip_trialTypes(obj)

        add_focus_trialTypes(obj)
        
        portInfo = find_port(obj, varargin)


    %% Spike methods
        
        spikesByTrial = trialize_spikes(obj, trialStart)

        binnedSpikes = bin_spikes(obj, eventEdges, binSize, neuronNo)

        binnedTrials = bin_neuron(obj, neuron, varargin)

        binnedNeurons = bin_all_neurons(obj, varargin)

        h = raster(obj, neuron, varargin)

        smoothedSpikes = psth(obj, neuron, varargin)

        h = mean_population_response(obj, varargin)
        
        [zMean, zCells, trialNum] = z_score(obj, varargin)

        [corrScore, trialTypes] = xcorr(obj, event, edges)

        plot_xcorr(obj, ref, target, window)

        find_mono(obj)

        plot_mono(obj, varargin)

        G = plot_digraph(obj, trialized, panel)
    
        weightsEx = trialize_mono_excitatory(obj, varargin)
        
        weightsIn = trialize_mono_inhibitory(obj, trialType, alignment, edges, varargin)

        sigs = zeta_call(obj, event, varargin) 
        
        hctsa(obj, varargin)
    %% LFP methods

        [pwr, freqs, phase, lfpAll] = cwt_power(obj, varargin)

        [ppc_all, spikePhase, ppc_sig]  = ppc(obj, varargin)

        filteredLFP = filter_signal(obj, varargin)

        ITPC = itpc(obj, event, varargin)

        [lfp_all, chanPhase] = lfp_align(obj, varargin)

        [gcx] = gc(obj, varargin)

        %plot_cwt(pwr, channel, freqs, panel)   panel is an optional arg

    %% Video methods

        stateFrames = find_state_frames(obj, stateName, varargin)
        
        rotVec = trialize_rotation(obj, stateName, varargin)

        combinedOutput = combine_LabGym_outputs(obj, metric)

        [trializedBehavior, figH] = plot_LabGym_behaviors(obj, varargin)

        [trializedLocation, figH] = plot_centroid(obj, varargin)

        figH = plot_centroid_and_behaviors(obj, varargin)
        
        %[f, h] = rotation_surf(rotVec, panel)

        get_e3v_frame_times(obj, bncData)

        [timeSeriesData, labels, keywords] = hctsa_position_initialize(obj, presets)
        
        hctsa_position_calculate(obj, varargin)

        hctsa_position_plot(obj, varargin)

        hctsa_position(obj, varargin)
        
    %% Additional methods

        [timestamps, eventTrial] = find_event(obj, varargin)

        noiseRemoved = remove_noisy_periods(obj, rawData, event, varargin)

        bpodOffset = samplingDiff(obj)

        goodTrials = trial_intersection(obj, trializedEvents, presets)

        brTimes = bpod_to_blackrock(obj, bpodTimes, presets)

        keywords = hctsa_keywords(obj, varargin)

        
    end
end