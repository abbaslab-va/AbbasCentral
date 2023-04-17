% This class will manage arrays of BehDat objects. It will use the
% select_experiment function mechanics to organize sessions that
% can then be analyzed according to the needs of the analysis, be it by
% subject, by neuron, by session, etc.

classdef ExpManager < handle

    properties
        sessions        % array of all sessions 
        metadata        % experimental metadata from select_experiment
    end

    methods
        function obj = ExpManager(s, m)
            obj.sessions = s;
            obj.metadata = m;
        end

%         newExperiment = collect_sessions(expPath)

        function sessionIdx = subset(obj, containingString)
            sessionIdx = arrayfun(@(x) contains(x.info.path, containingString), ...
                obj.sessions);
        end
            

        %% Bpod methods
        
        %% Spike methods

        [rpIndices, smoothedPSTHs] = calculate_rp_neurons(obj, event, varargin)
        
        [rpIndices, smoothedPSTHs] = calculate_rp_neurons_startOfSess(obj)
        %% LFP methods
        
        %% Video methods
        
    end

end
