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
addParameter(p, 'edges', [0, 300*obj.info.baud], @isvector);
addParameter(p, 'binWidth', 50, validNumber)
parse(p, varargin{:});
a = p.Results;
edges = a.edges;
binWidth = a.binWidth;
numNeurons = numel(obj.spikes);
labels = cell(1, numNeurons);
[~, sessionName] = fileparts(obj.info.path);

% Format HCTSA output

timeSeriesData = obj.bin_spikes(edges, binWidth);
timeSeriesData = num2cell(timeSeriesData, 2)';
keywords = extractfield(obj.spikes, 'region');
for neuron = 1:numNeurons
    %   uncomment if you can figure out how to add multiple keywords
%     if obj.spikes(neuron).fr <= 5
%         fr = 'lo';
%     else
%         fr = 'hi';
%     end    
    
    labels{neuron} = [obj.info.name, '|', sessionName, '|', num2str(neuron)];
end

% cd(obj.info.path)
cd('E:\Ephys\Test')
save('hctsa_allTS.mat', 'timeSeriesData', 'labels', 'keywords')
TS_Init('hctsa_allTS.mat', {'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_mops_catch24.txt', 'E:\AbbasCentral\packages\hctsa\FeatureSets\INP_ops_catch24.txt'});
sample_runscript_matlab(true, 5);
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
