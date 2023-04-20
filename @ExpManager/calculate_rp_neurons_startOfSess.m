function [rpIndices, smoothedPSTHs] = calculate_rp_neurons_startOfSess(obj, event, varargin)

% Calculate rpNeurons and smoothed z-scored PSTH for all sessions
% INPUT:
%   - sessions: an array of expSessions objects
% OUTPUT:
%   - rpIndices: a cell array containing the indices of all rpNeurons for each session
%   - smoothedPSTHs: a cell array containing the smoothed z-scored PSTH for each session

% Parse inputs
p = inputParser;
validVectorSize = @(x) isvector(x) && length(x) == 2;
validInput = @(x) ischar(x) || isempty(x) || iscell(x);
addRequired(p, 'event', @ischar);
addParameter(p, 'baseline', 'Trial Start', @ischar);
addParameter(p, 'bWindow', [-1 0], validVectorSize);
addParameter(p, 'eWindow', [-1 1], validVectorSize);
addParameter(p, 'binWidth', 20, @isscalar);
addParameter(p, 'trialType', [], validInput);
addParameter(p, 'outcome', [], validInput);
addParameter(p, 'offset', 0, @isscalar);
parse(p, event, varargin{:});
a = p.Results;
baseline = a.baseline;
bWindow = a.bWindow;
eWindow = a.eWindow;
binWidth = a.binWidth;
trialType = a.trialType;
outcome = a.outcome;
offset = a.offset;
leftEdge = 300;     %ms
rightEdge = 100;    %ms

rpIndices = cell(size(obj.sessions));
smoothedPSTHs = cell(size(obj.sessions));

% This code finds the reward window in which to identify rp neurons, which
% will vary depending on the bin size. It tries to find the bins nearest to
% -300:-100 ms prior to the event
eSteps = eWindow(1)*1000:binWidth:eWindow(2)*1000;
relativeEvent = find(eSteps == min(abs(eSteps)));
if numel(relativeEvent) > 1
    relativeEvent = relativeEvent(1);
end
stepsBackLeftEdge = floor(leftEdge/binWidth);
stepsBackRightEdge = floor(rightEdge/binWidth) + 1;
rewardWindow = [relativeEvent - stepsBackLeftEdge, ...
    relativeEvent - stepsBackRightEdge];

for i = 1:numel(obj.sessions)
        % Calculate baselineMean and baselineSTD
    sess = obj.sessions(i);
    firstBlock = first_block_trials(sess.bpod);
    smoothedRewardPSTH = sess.z_score(event, 'baseline', baseline, 'bWindow', bWindow, ...
        'eWindow', eWindow, 'binWidth', binWidth, 'baseTrials', firstBlock, 'eventTrials', firstBlock, ...
        'trialType', trialType, 'outcome', outcome, 'offset', offset);
    rpNeurons = all(smoothedRewardPSTH(:, rewardWindow) > 1, 2);

    rpIndices{i} = find(rpNeurons);
    smoothedPSTHs{i} = smoothedRewardPSTH;
    
end
