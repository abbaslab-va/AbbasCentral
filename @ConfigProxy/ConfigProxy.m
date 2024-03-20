classdef ConfigProxy < handle

% This class manages the parsing of config.ini files, as well as stores the
% configurations from the files. This allows for BehDat as well as
% BpodParser to access the same methodology when requesting subsets of
% data.

    properties
        outcomes
        trialTypes
        stimTypes
        startState
    end

    methods

        function obj = ConfigProxy(iniPath)
            I = INI;
            I.read(iniPath)
            obj.outcomes = I.outcomes;
            obj.trialTypes = I.trialTypes;
            obj.stimTypes = I.stimTypes;
            obj.startState = I.info.StartState;
        end

        goodTrials = trial_intersection(obj, presets)

        
    end

end
