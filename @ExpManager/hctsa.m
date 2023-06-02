function hctsa(obj, varargin)
% This function will run the hctsa analysis on a subject.
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
keywordsAll = arrayfun(@(x) extractfield(x.spikes, 'region'), obj.sessions, 'uni', 0);
keywords = cat(2, keywordsAll{:});
labelsAll = arrayfun(@(x) get_labels(x), obj.sessions, 'uni', 0);
labels = cat(2, labelsAll{:});

cd('E:\Ephys\Test')
save('hctsa_allTS.mat', 'timeSeriesData', 'labels', 'keywords')
TS_Init('hctsa_allTS.mat', 'INP_mops.txt', 'INP_ops_reduced.txt');
sample_runscript_matlab();
% TS_LabelGroups('raw',labels);
TS_Normalize('mixedSigmoid',[0.5, 1.0]);

% Cluster
distanceMetricRow = 'euclidean'; % time-series feature distance
linkageMethodRow = 'average'; % linkage method
distanceMetricCol = 'corr_fast'; % a (poor) approximation of correlations with NaNs
linkageMethodCol = 'average'; % linkage method
TS_Cluster(distanceMetricRow, linkageMethodRow, distanceMetricCol, linkageMethodCol);

% Visualize
TS_PlotDataMatrix();

end

function labels = get_labels(session)
    [~, sessionName] = fileparts(session.info.path);
    numNeurons = numel(session.spikes);
    labels = cell(1, numNeurons);
    for neuron = 1:numNeurons
        labels{neuron} = [session.info.name, '|', sessionName, '|', num2str(neuron)];
    end
end