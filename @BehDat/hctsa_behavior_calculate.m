function hctsa_behavior_calculate(obj, varargin)

% This method uses find_event to trialize behavior data in order to use
% the hctsa analysis on the events.
cd(obj.info.path)
presets = PresetManager(varargin{:});

[timeSeriesData, labels, keywords] = obj.hctsa_behavior_initialize(presets);
[~, sessName] = fileparts(obj.info.path);
subSaveString = strcat('hctsa_behavior_', sessName, '_', num2str(presets.edges), '_', presets.event);
subSaveFile = strcat(subSaveString, '.mat');
normalizedFile = strcat(subSaveString, '_N.mat');
save(subSaveFile, 'timeSeriesData', 'labels', 'keywords');
TS_Init(subSaveFile, {'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_mops_catch24.txt', ...
    'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_ops_catch24.txt'}, true, subSaveFile, false);
sample_runscript_matlab(true, 5, subSaveFile);
% TS_LabelGroups('raw',labels);
TS_Normalize('mixedSigmoid',[0.5, 1.0], subSaveFile);    
% Cluster
distanceMetricRow = 'euclidean'; % time-series feature distance
linkageMethodRow = 'average'; % linkage method
distanceMetricCol = 'corr_fast'; % a (poor) approximation of correlations with NaNs
linkageMethodCol = 'average'; % linkage method
TS_Cluster(distanceMetricRow, linkageMethodRow, distanceMetricCol, linkageMethodCol, true, normalizedFile);
