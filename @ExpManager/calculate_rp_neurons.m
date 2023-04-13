function [rpIndices, smoothedPSTHs] = calculate_rp_neurons(obj, event, varargin)

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
addParameter(p, 'binWidth', 1, @isscalar);
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
rpIndices = cell(size(obj.sessions));
smoothedPSTHs = cell(size(obj.sessions));
for i = 1:numel(obj.sessions)
    
    % Calculate baselineMean and baselineSTD
    smoothedRewardPSTH = obj.sessions(i).z_score(event, 'baseline', baseline, 'bWindow', bWindow, ...
        'eWindow', eWindow, 'binWidth', binWidth, ...
        'trialType', trialType, 'outcome', outcome, 'offset', offset);
    % Identify rpNeurons
    rpNeurons = all(smoothedRewardPSTH(:, 600:900) > 1.5, 2);

    rpIndices{i} = find(rpNeurons);
    smoothedPSTHs{i} = smoothedRewardPSTH;
end
