function [numTT, numCorrect] = performance(obj, varargin)
% This function returns a vector by trial type of the number of completed trials of each trial type, 
% as well as the number correctly completed for the trial type of interest.
%
% Example call: [numTT, numCorrect] = bpod_performance(bpodSession, correctOutcome)
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
goodTrials = obj.trial_intersection_BpodParser('preset', presets);

if isempty(presets.outcome)
    correctOutcome = 1;
else
    correctOutcome = presets.outcome;
end

%Must have the SessionPerformance variable saved to the Bpod structure to use this function
perfException = MException('MATLAB:missingVariable', 'Error: No SessionPerformance variable found in bpodSession');
%User can enter an integer value as the second argument to change the default outcome evaluation

trialTypes = obj.session.TrialTypes;
nTT = numel(unique(trialTypes));
if ~isfield(obj.session, 'SessionPerformance')
    throw(perfException)
end
numTT = zeros(1, nTT);
numCorrect = numTT;
for tt = 1:nTT
    ttInd = obj.session.TrialTypes(goodTrials) == tt;
    numTT(tt) = numel(find(ttInd));
    numCorrect(tt) = numel(find(obj.session.SessionPerformance(ttInd) == correctOutcome));
end