function [numTT, numCorrect] = calculate_performance(obj, varargin)
%
% This method calculates the bpod performance of all animals present in an
% experiment by session or by animal, and can be thresholded by performance
% or viewed by trialType or stimType subsets.
% INPUT:
    % trialType, stimType, outcome, subset, session, animal

% ConfigProxy controls
presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'threshold', .65, @isnumeric);
addParameter(p, 'comparison', 'sessions', @ischar)
parse(p, varargin{:});

% performance by animal or by session
[numTT, numCorrect] = arrayfun(@(x) ...
    x.bpod.performance('preset', presets), ...
    obj.sessions, 'uni', 0);

goodSessions = obj.subset('animal', presets.animal);

numTT = numTT(goodSessions);
numCorrect = numCorrect(goodSessions);

% performance threshold
% plots?