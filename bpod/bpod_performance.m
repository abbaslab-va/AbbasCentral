function [numTT, numCorrect] = bpod_performance(parserObj, correctOutcome, goodTrials)

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

if isa(parserObj, 'BpodParser')
    bpodSession = parserObj.session;
else
    bpodSession = parserObj;
end

%Must have the SessionPerformance variable saved to the Bpod structure to use this function
perfException = MException('MATLAB:missingVariable', 'Error: No SessionPerformance variable found in bpodSession');
%User can enter an integer value as the second argument to change the default outcome evaluation

nTrials = bpodSession.nTrials;
trialTypes = bpodSession.TrialTypes;
nTT = max(trialTypes);
if ~exist('correctOutcome', 'var')
    correctOutcome = 1;
end
if ~exist('goodTrials', 'var')
    goodTrials = true(1, nTrials);
end
if ~isfield(bpodSession, 'SessionPerformance')
    throw(perfException)
end
for tt = 1:nTT
    ttInd = find(bpodSession.TrialTypes == tt & goodTrials);
    numTT(tt) = numel(ttInd);
    numCorrect(tt) = numel(find(bpodSession.SessionPerformance(ttInd) == correctOutcome));
end