function hctsa_position_plot(obj, varargin)

% This method uses find_event to trialize coordinate data in order to use
% the hctsa analysis on the events.
cd(obj.info.path)
presets = PresetManager(varargin{:});

if isempty(presets.outcome)
    outcomeLabel = {};
elseif ischar(presets.outcome)
    outcomeLabel = {presets.outcome};
elseif iscell(presets.outcome)
    outcomeLabel = presets.outcome;
end

if isempty(presets.trialType)
    ttLabel = {};
elseif ischar(presets.trialType)
    ttLabel = {presets.trialType};
elseif iscell(presets.trialType)
    ttLabel = presets.trialType;
end

groupLabels = [outcomeLabel, ttLabel];
[~, sessName] = fileparts(obj.info.path);
subSaveString = strcat('hctsa_position_', sessName, '_', presets.event);
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
    error('No save file found, run hctsa_position_calculate with the same presets')
end
