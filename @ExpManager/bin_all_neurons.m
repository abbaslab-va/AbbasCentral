function binnedSpikes = bin_all_neurons(obj, varargin)

% ExpManager wrapper for the BehDat method
presets = PresetManager(varargin{:});
whichSessions = obj.subset('preset', presets);

binnedSpikes = arrayfun(@(x) x.bin_all_neurons('preset', presets), obj.sessions(whichSessions), 'uni', 0);
