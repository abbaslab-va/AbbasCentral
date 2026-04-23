function responseIdx = calculate_event_neurons(obj, varargin)

% A BehDat method to identify neurons that are active or suppressed 
% at the time of a PresetManager event.
%
% INPUT: 
    % 'threshold' - a float describing the threshold value
% OUTPUT:
    % responseIdx - a boolean array identifying responsive neurons

validVectorSize = @(x) all(size(x) == [1, 2]);
presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
p.addParameter('threshold', 1, @isfloat)
p.addParameter('window', [-50 50], validVectorSize)
parse(p, varargin{:});
window = p.Results.window;
threshold = p.Results.threshold;

responseIdx = obj.threshold_window(presets, window, threshold);