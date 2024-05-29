classdef ExpManager < handle

% This class will manage arrays of BehDat objects. It will use the
% select_experiment function mechanics to organize sessions that
% can then be analyzed according to the needs of the analysis, be it by
% subject, by neuron, by session, etc.

    properties
        sessions        % array of all sessions 
        metadata        % experimental metadata from select_experiment
    end

    methods
        function obj = ExpManager(s, m)
            obj.sessions = s;
            obj.metadata = m;
        end

%         newExperiment = collect_sessions(expPath)     % collect all sessions in a directory, not an ExpManager method


        function get_size(obj) 
            props = properties(obj); 
            totSize = 0; 
           
            for ii=1:length(props) 
                s = whos('currentProperty'); 
                totSize = totSize + s.bytes;
                for sess = 1:numel(obj.sessions)
                    totSize = totSize + obj.sessions(sess).get_size;
                end
            end
          
            fprintf(1, '%d bytes\n', totSize); 
        end
            
        function copy(obj, copyObj)
            propNames = properties(obj);
            for prop = 1:numel(propNames)
                currentProp = propNames{prop};
                if strcmp(currentProp, "sessions")
                    for s = 1:numel(copyObj.sessions)
                        obj.sessions(s) = BehDat();
                        obj.sessions(s).copy(copyObj.sessions(s))
                    end
                elseif isa(copyObj.(currentProp), 'handle')
                    obj.(currentProp) = eval(class(copyObj.(currentProp)));
                    obj.(currentProp).copy(copyObj.(currentProp));
                else
                    obj.(currentProp) = copyObj.(currentProp);
                end
            end
        end

        %% Bpod methods
        
        plot_performance(obj, varargin)

        [numTT, numCorrect] = calculate_performance(obj, varargin)

        %% Spike methods

        [rpIndices, smoothedPSTHs] = calculate_rp_neurons(obj, event, varargin)

        [rpIndices, smoothedPSTHs] = calculate_rp_neurons_startOfSess(obj, event, varargin)
        
        [rpIndices, smoothedPSTHs] = calculate_outcome_neurons(obj, event, varargin)

        binnedSessions = bin_spikes(obj, varargin)

        hctsa(obj, varargin)
        
        hctsa_fr(obj, varargin)

        %% LFP methods
        
        %% Video methods
        
        hctsa_position(obj, varargin)

        hctsa_behavior(obj, varargin)

        [trializedBehavior, numericalBehavior, figH] = plot_combined_behaviors(obj, varargin)
        
        %% Other

        sessionIdx = subset(obj, varargin)
    end

end
