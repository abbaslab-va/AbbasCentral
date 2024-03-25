function [numTT, numCorrect] = outcomes(obj, varargin)

% This function returns a vector by trial type of the number of completed trials of each trial type, 
% as well as the number correctly completed for the trial type of interest.
%
% INPUT: 
%     bpodSession - a Bpod behavior session file
%     correctOutcome - optionally include an integer value in your function call to
%     calculate performance outcomes other than 1.
% OUTPUT:
%     numTT - 1xT vector where T is the number of trial types. Stores # of each
%     trial type completed in bpodSession
%     numCorrect - 1xT vector where T is the number of trial types. Stores #
%     of trial types with the outcome specified by varargin. If no argument
%     is given, the default outcome returned by numCorrect is for 1.

presets = PresetManager(varargin{:});
if isempty(presets.outcome)
    outcome = 1;
end

if isa(obj.bpod, 'BpodParser')
    bpodStruct = obj.bpod.session;
else
    bpodStruct = obj.bpod;
end

if isempty(presets.trialType)
    [numTT, numCorrect] = bpod_performance(obj.bpod.session, outcome);
    return
elseif isa(obj.bpod, 'BpodParser')
    trialType = obj.bpod.config.trialTypes.(presets.trialType);
else
    trialType = obj.info.trialTypes.(presets.trialType);
end

[numTT, numCorrect] = bpod_performance(bpodStruct, outcome);
numTT = numTT(trialType);
numCorrect = numCorrect(trialType);
