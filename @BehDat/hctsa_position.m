function hctsa_position(obj, varargin)

    % This method uses find_event to trialize coordinate data in order to use
    % the hctsa analysis on the events.
    cd('E:/Ephys/Test')
    presets = PresetManager(varargin{:});
    
    coordinates = obj.plot_centroid('event', presets.event, 'plot', false);
    resolution = [270 150]; % hardcoded for LabGym paper - obj should store this
    badCoords = cellfun(@(x) x == 0, coordinates, 'uni', 0);
    for t = 1:numel(coordinates)
        coordinates{t}(badCoords{t}) = 1;
    end
    timeSeriesData = cellfun(@(x) sub2ind(resolution, round(x(:, 1)), round(x(:, 2))), coordinates, 'uni', 0);
    trialNo = num2cell(1:numel(timeSeriesData));
    trialString = cellfun(@(x) num2str(x), trialNo, 'uni', 0);
    labels = cellfun(@(x) strcat(obj.info.name, '_', x), trialString, 'uni', 0);
    keywords = obj.hctsa_keywords('preset', presets);

    subSaveString = strcat('hctsa_position_', obj.info.name, '_', presets.event);
    subSaveFile = strcat(subSaveString, '.mat');

    save(subSaveFile, 'timeSeriesData', 'labels', 'keywords');
    TS_Init(subSaveFile, {'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_mops_catch24.txt', ...
        'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_ops_catch24.txt'}, true, subSaveFile);
    sample_runscript_matlab(true, 5, subSaveFile);
    % TS_LabelGroups('raw',labels);
    TS_Normalize('mixedSigmoid',[0.5, 1.0], subSaveFile);    
    % Cluster
    distanceMetricRow = 'euclidean'; % time-series feature distance
    linkageMethodRow = 'average'; % linkage method
    distanceMetricCol = 'corr_fast'; % a (poor) approximation of correlations with NaNs
    linkageMethodCol = 'average'; % linkage method
    TS_Cluster(distanceMetricRow, linkageMethodRow, distanceMetricCol, linkageMethodCol, true, strcat(subSaveString, '_N.mat'));
    % Visualize
    TS_LabelGroups(strcat(subSaveString, '_N.mat'), {'Sample1', 'Sample2', 'Sample3'});
    TS_PlotDataMatrix('whatData', strcat(subSaveString, '_N.mat'));
    TS_PlotLowDim(strcat(subSaveString, '_N.mat'));
end