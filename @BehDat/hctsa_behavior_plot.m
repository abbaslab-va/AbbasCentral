function hctsa_behavior_plot(obj, varargin)

cd(obj.info.path)
presets = PresetManager(varargin{:});

if isempty(presets.outcome)
    outcomeLabel = {};
    if isempty(presets.trialType)
        ttLabel = {};
    elseif ischar(presets.trialType)
        ttLabel = {presets.trialType};
    elseif iscell(presets.trialType)
        ttLabel = presets.trialType;
    end
elseif ischar(presets.outcome)
    outcomeLabel = {presets.outcome};
    ttLabel = {};
elseif iscell(presets.outcome)
    outcomeLabel = presets.outcome;
    ttLabel = {};
end

groupLabels = [outcomeLabel, ttLabel];
[~, sessName] = fileparts(obj.info.path);
subSaveString = strcat('hctsa_behavior_', sessName, '_', presets.event);
normalizedFile = strcat(subSaveString, '_N.mat');
try
    % Visualize
    TS_LabelGroups(normalizedFile, groupLabels);
    % TS_PlotDataMatrix('whatData', normalizedFile);
    if ~isempty(presets.panel)
        figH = TS_PlotLowDim(normalizedFile);
        set(gca, 'color', 'w')
        copyobj(figH.Children, presets.panel)
        close(figH)
    else
        TS_PlotLowDim(normalizedFile);
    end

catch
    error('No save file found, run hctsa_behavior_calculate with the same presets')
end
