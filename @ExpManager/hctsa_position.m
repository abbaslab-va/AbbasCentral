function hctsa_position(obj, varargin)

% This method will calculate hctsa on trialized coordinate data across all
% animals, or on all sessions on the specified animal.

cd('E:/Ephys/Test')
presets = PresetManager(varargin{:});
fileDir = dir;
fileNames = extractfield(fileDir, 'name');

whichSessions = obj.subset('animal', presets.animals);
if ~isempty(presets.animals)
    subNames = join(presets.animals, '+');
end
edgeStr = num2str(presets.edges);
saveString = strcat('hctsa_position_all_', presets.event, '_', edgeStr, '_', subNames);
saveFile = strcat(saveString, '.mat');
normalizedFile = strcat(saveString, '_N.mat');

if ~ismember(saveFile, fileNames)

    [timeSeriesData, labels, keywords] = arrayfun(@(x) x.hctsa_position_initialize(presets), obj.sessions(whichSessions), 'uni', 0);
    timeSeriesData = cat(1, timeSeriesData{:});
    labels = cat(2, labels{:})';
    keywords = cat(2, keywords{:})';
    
    
    save(saveFile, 'timeSeriesData', 'labels', 'keywords');
    TS_Init(saveFile, {'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_mops_catch24.txt', ...
        'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_ops_catch24.txt'}, false, saveFile, false);
    sample_runscript_matlab(true, 5, saveFile);
end
% TS_LabelGroups('raw',labels);
TS_Normalize('mixedSigmoid',[0.5, 1.0], saveFile);    
% Cluster
distanceMetricRow = 'euclidean'; % time-series feature distance
linkageMethodRow = 'average'; % linkage method
distanceMetricCol = 'corr_fast'; % a (poor) approximation of correlations with NaNs
linkageMethodCol = 'average'; % linkage method
TS_Cluster(distanceMetricRow, linkageMethodRow, distanceMetricCol, linkageMethodCol, true, normalizedFile);

if isempty(presets.outcome)
    trialID = TS_GetIDs('Correct', normalizedFile);
    
    % timeSeriesData = timeSeriesData(correctTrials);
    % labels = labels(correctTrials);
    % keywords = keywords(correctTrials);
else
    trialID = TS_GetIDs(presets.trialType, normalizedFile);
    % timeSeriesData = timeSeriesData(whichTrials);
    % labels = labels(whichTrials);
    % keywords = keywords(whichTrials);
end

TS_Subset(normalizedFile, trialID, [], 1, 'temp_subset.mat')

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

% if isempty(praesets.trialType)
%     ttLabel = {};
% elseif ischar(presets.trialType)
%     ttLabel = {presets.trialType};
% elseif iscell(presets.trialType)
%     ttLabel = presets.trialType;
% end

groupLabels = [outcomeLabel, ttLabel];
% try
    % Visualize
    TS_LabelGroups('temp_subset.mat', groupLabels);
    % TS_PlotDataMatrix('whatData', normalizedFile, 'colorGroups', true);
    if ~isempty(presets.panel)
        figH = TS_PlotLowDim('temp_subset.mat', 'pca', false, 0);
        set(gca, 'color', 'w')
        
        arrayfun(@(x)copyobj(x, presets.panel), figH.Children(2).Children)
        classificationStr = figH.Children(2).Title.String;
        classificationPctIdx = regexp(classificationStr, '[\.\%0-9]');
        title(presets.panel, classificationStr(classificationPctIdx))
        close(figH)
    else
        TS_PlotLowDim('temp_subset.mat', 'pca', false, 0);
    end

% catch
%     error('No save file found, run hctsa_position_calculate with the same presets')
% end
