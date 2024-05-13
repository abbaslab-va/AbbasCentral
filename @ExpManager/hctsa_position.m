function hctsa_position(obj, varargin)

% This method will calculate hctsa on trialized coordinate data across all
% animals, or on all sessions on the specified animal.

cd('E:/Ephys/Test')
presets = PresetManager(varargin{:});
fileDir = dir;
fileNames = extractfield(fileDir, 'name');


whichSessions = obj.subset(presets.animals);
if ~isempty(presets.animals)
    subNames = join(presets.animals, '+');
end
saveString = strcat('hctsa_position_all_', presets.event, '_', subNames);
saveFile = strcat(saveString, '.mat');
normalizedFile = strcat(saveString, '_N.mat');

% if ~ismember(normalizedFile, fileNames)

    [timeSeriesData, labels, keywords] = arrayfun(@(x) x.hctsa_position_initialize(presets), obj.sessions(whichSessions), 'uni', 0);
    timeSeriesData = cat(1, timeSeriesData{:});
    labels = cat(2, labels{:})';
    keywords = cat(2, keywords{:})';
    
    
    save(saveFile, 'timeSeriesData', 'labels', 'keywords');
    TS_Init(saveFile, {'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_mops_catch24.txt', ...
        'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_ops_catch24.txt'}, true, saveFile, false);
    sample_runscript_matlab(true, 5, saveFile);
    % TS_LabelGroups('raw',labels);
    TS_Normalize('mixedSigmoid',[0.5, 1.0], saveFile);    
    % Cluster
    distanceMetricRow = 'euclidean'; % time-series feature distance
    linkageMethodRow = 'average'; % linkage method
    distanceMetricCol = 'corr_fast'; % a (poor) approximation of correlations with NaNs
    linkageMethodCol = 'average'; % linkage method
    TS_Cluster(distanceMetricRow, linkageMethodRow, distanceMetricCol, linkageMethodCol, true, normalizedFile);
% end

if isempty(presets.region)
    regionLabel = {};
elseif ischar(presets.trialType)
    regionLabel = {presets.region};
elseif iscell(presets.trialType)
    regionLabel = presets.region;
end

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

groupLabels = [outcomeLabel, ttLabel, regionLabel];
try
    % Visualize
    TS_LabelGroups(normalizedFile, groupLabels);
    % TS_PlotDataMatrix('whatData', normalizedFile, 'colorGroups', true);
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
