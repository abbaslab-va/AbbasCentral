function hctsa_position(obj, varargin)

% This method will calculate hctsa on trialized coordinate data across all
% animals, or on all sessions on the specified animal.

cd ('E:/Ephys/Test')
presets = PresetManager(varargin{:});
whichSessions = obj.subset(presets.animals);

for 