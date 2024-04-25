function hctsa_fr(obj, varargin)

% This method will calculate hctsa on trialized z-scored firing rate
% data across all animals, or on all sessions on the specified animal.

cd('E:/Ephys/Test')
presets = PresetManager(varargin{:});
whichSessions = obj.subset(presets.animals);

[timeSeriesData, labels, keywords] = arrayfun(@(x) x.hctsa_fr_initialize(presets), obj.sessions(whichSessions), 'uni', 0);
timeSeriesData = cat(1, timeSeriesData{:});
labels = cat(2, labels{:})';
keywords = cat(2, keywords{:})';


saveString = strcat('hctsa_fr_all_', presets.event);
saveFile = strcat(saveString, '.mat');
normalizedFile = strcat(saveString, '_N.mat');
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

if isempty(presets.region)
    regionLabel = {};
elseif ischar(presets.trialType)
    regionLabel = {presets.region};
elseif iscell(presets.trialType)
    regionLabel = presets.region;
end

% groupLabels = [outcomeLabel, ttLabel];
groupLabels = regionLabel;
try
    % Visualize
    TS_LabelGroups(normalizedFile, groupLabels);
    TS_PlotDataMatrix('whatData', normalizedFile);
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
