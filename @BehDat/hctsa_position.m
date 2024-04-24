function hctsa_position(obj, varargin)

cd(obj.info.path)
presets = PresetManager(varargin{:});

[~, sessName] = fileparts(obj.info.path);
subSaveString = strcat('hctsa_position_', sessName, '_', presets.event);
normalizedFile = strcat(subSaveString, '_N.mat');

localFiles = dir;
fileNames = extractfield(localFiles, 'name');
if ~any(strcmp(normalizedFile, fileNames))
    obj.hctsa_position_calculate('preset', presets);
end
obj.hctsa_position_plot('preset', presets);