function goodTrials = trial_intersection(obj, varargin)

% Abstracts away some complexity from the find_event and find_bpod_event
% functions. Calculates trial set intersections
% 
% OUTPUT:
%     goodTrials - logical vector for indexing trial sets
% INPUT:
%     presets - a PresetManager object

goodTrials = obj.bpod.trial_intersection_BpodParser(varargin{:});