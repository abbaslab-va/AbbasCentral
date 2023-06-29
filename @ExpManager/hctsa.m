function hctsa(obj, varargin)
% This function will run the hctsa analysis on an experiment.
% B.D. Fulcher and N.S. Jones. hctsa: A computational framework for automated time-series phenotyping using massive feature extraction. Cell Systems: 5, 527 (2017).
% B.D. Fulcher, M.A. Little, N.S. Jones. Highly comparative time-series analysis: the empirical structure of time series and their methods. J. Roy. Soc. Interface: 10, 83 (2013).
%
% OUTPUT:
% INPUT:
%     edges - a vector of bin edges to bin spikes within
%     binWidth - a positive integer bin width in ms (default 50)

validNumber = @(x) isnumeric(x) && x > 0;
p = inputParser;
addParameter(p, 'edges', [0, 300*obj.sessions(1).info.baud], @isvector);
addParameter(p, 'binWidth', 50, validNumber)
parse(p, varargin{:});
a = p.Results;
edges = a.edges;
binWidth = a.binWidth;

% Format HCTSA output
tsAll = arrayfun(@(x) x.bin_spikes(edges, binWidth), obj.sessions, 'uni', 0);
timeSeriesData = cat(1, tsAll{:});
timeSeriesData = num2cell(timeSeriesData, 2)';
try
    cellTypeAll =  arrayfun(@(x) extractfield(x.spikes, 'cellType'), obj.sessions, 'uni', 0);
    cellTypeAll = cat(2, cellTypeAll{:});
    emptyCellType = cellfun(@(x) isempty(x), cellTypeAll);
    [cellTypeAll{emptyCellType}] = deal('Unknown');
catch
end
regionsAll = arrayfun(@(x) extractfield(x.spikes, 'region'), obj.sessions, 'uni', 0);
regionsAll = cat(2, regionsAll{:});
emptyRegions = cellfun(@(x) isempty(x), regionsAll);
[regionsAll{emptyRegions}] = deal('Unknown');
if exist('cellTypeAll', 'var')
    keywords = cellfun(@(x, y) strcat(x, ',', y), cellTypeAll, regionsAll, 'uni', 0);
else
    keywords = regionsAll;
end
labelsAll = arrayfun(@(x) get_labels(x), obj.sessions, 'uni', 0);
labels = cat(2, labelsAll{:});

% Extract waveform features in same order
hpw = arrayfun(@(x) extractfield(x.spikes, 'halfPeakWidth'), obj.sessions, 'uni', 0);
fr = arrayfun(@(x) extractfield(x.spikes, 'fr'), obj.sessions, 'uni', 0);
waveformFeatures = [cat(2, hpw{:}); cat(2, fr{:})];
% Save locally for now because I don't have permission to save to randall's
% computer
userDir = uigetdir;
cd(userDir)
save('hctsa_allTS.mat', 'timeSeriesData', 'labels', 'keywords')
TS_Init('hctsa_allTS.mat', 'INP_mops.txt', 'INP_ops_reduced.txt');
sample_runscript_matlab();
% TS_LabelGroups();
TS_Normalize('mixedSigmoid',[0.5, 1.0]);

% Cluster
distanceMetricRow = 'euclidean'; % time-series feature distance
linkageMethodRow = 'average'; % linkage method
distanceMetricCol = 'corr_fast'; % a (poor) approximation of correlations with NaNs
linkageMethodCol = 'average'; % linkage method
TS_Cluster(distanceMetricRow, linkageMethodRow, distanceMetricCol, linkageMethodCol);

% Visualize
TS_PlotDataMatrix();

% PCA/kMeans
%Must load HCTSA_N.mat before this
figure
load('HCTSA_N.mat')
[~, score] = pca(TS_DataMat);
scores = score(:, 1:3);
idx = kmeans(scores, 4, 'Distance', 'cityblock', 'Replicates', 5);
idxcolors(idx == 1, :) = repmat([1 0 0], numel(find(idx == 1)), 1);
idxcolors(idx == 2, :) = repmat([0 0 1], numel(find(idx == 2)), 1);
idxcolors(idx == 3, :) = repmat([0 1 0], numel(find(idx == 3)), 1);
idxcolors(idx == 4, :) = repmat([0 1 1], numel(find(idx == 4)), 1);
scatter3(scores(:, 1), scores(:, 2), scores(:, 3), 15, idxcolors, 'filled')
waveformFeatures = waveformFeatures(:, 1:size(idxcolors, 1));
figure
scatter(waveformFeatures(1, :), waveformFeatures(2, :), 15, idxcolors, 'filled')
xlabel('Half Peak Width')
ylabel('Firing Rate')

figure
tsKeywords = TimeSeries.Keywords;
pvNeurons = cellfun(@(x) contains(x, 'PV'), tsKeywords);
somNeurons = cellfun(@(x) contains(x, 'SST'), tsKeywords);
vipNeurons = cellfun(@(x) contains(x, 'VIP'), tsKeywords);
pyramidalNeurons = cellfun(@(x) contains(x, 'Axo'), tsKeywords);
idxcolors(pvNeurons, :) = repmat([1 0 0], numel(find(pvNeurons)), 1);
idxcolors(somNeurons, :) = repmat([0 0 1], numel(find(somNeurons)), 1);
idxcolors(vipNeurons, :) = repmat([0 1 0], numel(find(vipNeurons)), 1);
idxcolors(pyramidalNeurons, :) = repmat([0 1 1], numel(find(pyramidalNeurons)), 1);
scatter3(scores(:, 1), scores(:, 2), scores(:, 3), 15, idxcolors, 'filled')
figure
scatter(waveformFeatures(1, :), waveformFeatures(2, :), 15, idxcolors, 'filled')
xlabel('Half Peak Width')
ylabel('Firing Rate')
% scatter3(scores(:, 1), scores(:, 2), scores(:, 3), 15, idx, 'filled')
end

function labels = get_labels(session)
    [~, sessionName] = fileparts(session.info.path);
    numNeurons = numel(session.spikes);
    labels = cell(1, numNeurons);
    for neuron = 1:numNeurons
        labels{neuron} = [session.info.name, '|', sessionName, '|', num2str(neuron)];
    end
end