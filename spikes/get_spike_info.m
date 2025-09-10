function spikeStruct = get_spike_info(sessPath, regions, includeMua, includeWaveforms)
    
% OUTPUT:
%     spikeStruct - a non-scalar structure containing spike info for a BehDat class
% INPUT:
%     sessPath - path to the behavioral session folder
%     regions - regions sourced from ini.regions. See docs for details
%   includeMua - flag to include mua units
%   includeWaveforms - flag to include waveforms, uses lots of memory

%Getting spike info from Kilosort3 files

unsortedSpikeTimes = double(readNPY(strcat(sessPath, '\spike_times.npy')));
unsortedSpikeClusters = double(readNPY(strcat(sessPath, '\spike_clusters.npy')))+1;
try clusterInfo = tdfread(strcat(sessPath, '\cluster_info.tsv'));
catch 
    spikeStruct = get_spike_info_noPhy(sessPath);
    return
end
%Combining your manually curated clusters (if any) with those that kilosort
%automatically assigns
nameFields = fields(clusterInfo);
if any(cellfun(@(x) strcmp(x, "cluster_id"), nameFields))
    idField = "cluster_id";
else
    idField = "id";
end
clusterID = num2cell(clusterInfo.(idField) + 1);
for cluster = 1:length(clusterInfo.(idField))
    if isnan(clusterInfo.group(cluster,1))
        clusterInfo.group(cluster,1) = clusterInfo.KSLabel(cluster,1); 
    elseif regexp('   ', clusterInfo.group(cluster,:)) == 1
        clusterInfo.group(cluster,1) = clusterInfo.KSLabel(cluster,1);
    elseif regexp('    ', clusterInfo.group(cluster,:)) == 1
        clusterInfo.group(cluster,1) = clusterInfo.KSLabel(cluster,1);
    elseif regexp('     ', clusterInfo.group(cluster,:)) == 1
        clusterInfo.group(cluster,1) = clusterInfo.KSLabel(cluster,1);
    end
end

%Pulling out only the clusters labeled 'good' (the ones that start with a 'g')
%and putting them into a matrix called GoodClusters
goodClusters = clusterInfo.(idField)(ismember(clusterInfo.group(:,1),'g') == 1)+1;
muaClusters = clusterInfo.(idField)(ismember(clusterInfo.group(:,1),'m') == 1)+1;
% noiseClusters = clusterInfo.(idField)(ismember(clusterInfo.group(:, 1), 'n') == 1)+1;
if isempty(goodClusters)
    spikeStruct=[];
    return 
end
clusterInfo.ch = clusterInfo.ch + 1; 
goodChannels = clusterInfo.ch(ismember(clusterInfo.group(:,1),'g') == 1); 
muaChannels = clusterInfo.ch(ismember(clusterInfo.group(:, 1),'m') == 1);
% logical to index original KSLabels and cluster id
idxKS = cellfun(@(x) strcmp(x,'g') || strcmp(x, 'good') || strcmp(x, 'mua'), cellstr(clusterInfo.group)); 
% note: above, I added strcmp(x,'g') || because I found one cluster info
% with the label 'g    ' instead of 'good ', I don't know how that
% occurred...
KSLabels = cellfun(@(x) regexprep(x, ' ', ''), (cellstr(clusterInfo.KSLabel(idxKS, :))), 'uni', 0);
clusterID = clusterID(idxKS);

goodChannels = num2cell(goodChannels);
muaChannels = num2cell(muaChannels);
numGoodCells = length(goodClusters);
numMuaCells = length(muaClusters);

muaArray = cell(numMuaCells, 1);

if includeMua
    numNeurons = numGoodCells + numMuaCells;
else
    numNeurons = numGoodCells;
end
spikeTimeArray = cell(numGoodCells, 1);

goodCellRegions = cell(numGoodCells, 1);
muaCellRegions = cell(numMuaCells, 1);
allRegions = fields(regions);
for cluster = 1:numGoodCells
    spikeTimeArray{cluster} = (unsortedSpikeTimes(unsortedSpikeClusters == goodClusters(cluster))');
    for r = 1:numel(allRegions)
        regionField = allRegions{r};
        if ismember(goodChannels{cluster}, regions.(regionField))
            goodCellRegions{cluster} = regionField;
            break
        end
    end
end

for cluster = 1:numMuaCells
    muaArray{cluster} = (unsortedSpikeTimes(unsortedSpikeClusters == muaClusters(cluster))');
    for r = 1:numel(allRegions)
        regionField = allRegions{r};
        if ismember(muaChannels{cluster}, regions.(regionField))
            muaCellRegions{cluster} = regionField;
            break
        end
    end
end


% Get Waveforms and Waveform metrics
[~, child] = fileparts(sessPath);
NS6 = openNSx(fullfile(sessPath,strcat(child,'.ns6')));
if ~isa(NS6,'struct') && NS6 == -1
    NS6_dir = dir([sessPath,'\*.ns6']);
    NS6 = openNSx(fullfile(sessPath,NS6_dir.name));    
end
% This rearranges the NS6 data so that each row corresponds to the channel
% signal for the corresponding neuron. This means some rows will be
% duplicates, but it makes it a slice variable instead of a broadcast
% variable for the parfor loop (for speed)

if includeMua
    numNeurons = numGoodCells + numMuaCells;
    goodLabels = cell(numGoodCells, 1);
    [goodLabels{:}] = deal('good');
    spikeTimeArray = [spikeTimeArray; muaArray];
    goodCellRegions = [goodCellRegions; muaCellRegions];
    muaLabels = cell(numMuaCells, 1);
    [muaLabels{:}] = deal('mua');
    neuronLabels = [goodLabels; muaLabels];

    neuronChannels = NS6.Data([cell2mat(goodChannels); cell2mat(muaChannels)], :);
    goodChannels = [goodChannels; muaChannels];
else
    numNeurons = numGoodCells;
    goodLabels = cell(numNeurons, 1);
    [goodLabels{:}] = deal('good');
    neuronLabels = goodLabels;
    neuronChannels = NS6.Data(cell2mat(goodChannels), :);
end
numSamples = length(NS6.Data);
clear NS6
minSpikes = 1000;
numSpikes = cellfun(@(x) length(x), spikeTimeArray);
enoughSpikes = numSpikes > minSpikes;


numSpikes = numSpikes(enoughSpikes);
padSize = 500;
padding = [-padSize padSize];
waveformRange = 1 + padSize - 50: 1 + padSize + 50;
spikeTimeArray = spikeTimeArray(enoughSpikes);

numNeurons = nnz(enoughSpikes);

fr = cell(numNeurons,1);
for neuron = 1:numNeurons
    fr{neuron} = numSpikes(neuron)/(numSamples/30000);
end
 if includeWaveforms
spikeInds = arrayfun(@(x) randsample(x, minSpikes), numSpikes, 'uni', 0);
spikeTimes = cellfun(@(x, y) x(y), spikeTimeArray, spikeInds, 'uni', 0);
waveformEdges = cellfun(@(x) num2cell(x' + padding, 2), spikeTimes, 'uni', 0);
goodEdges = cellfun(@(x) cellfun(@(y) ...
    all(y <= numSamples) && all(y >= 1), x), waveformEdges, 'uni', 0);
waveformEdges = cellfun(@(x, y) x(y), waveformEdges, goodEdges, 'uni', 0);
% 
waveformData = cellfun(@(x, z) cellfun(@(y) x(y(1):y(2)), z, 'uni', 0), ...
    num2cell(neuronChannels(enoughSpikes, :), 2), waveformEdges, 'uni', 0);
clear neuronChannels
% numNeurons = numel(waveformData);

averageWaveforms = cell(numNeurons,1);
% fr = averageWaveforms;
halfValleyWidth = averageWaveforms;
halfPeakWidth = averageWaveforms;
peak2valley = averageWaveforms;

parfor neuron = 1:numNeurons
    % fr{neuron} = numSpikes(neuron)/(numSamples/30000);
try
   
    filteredData = cellfun(@(x) ...
        highpass(single(x), 500, 30000), waveformData{neuron}, 'uni', 0);
    filteredData = cat(1, filteredData{:});
    

    % Waveform metrics
    averageWaveforms{neuron} = mean(filteredData(:, waveformRange), 1);
    [~, ~, w, p] = findpeaks(averageWaveforms{neuron});
    [~, maxIdx] = max(p);
    halfValleyWidth{neuron} = w(maxIdx);
    peak2valley{neuron} = abs(min(averageWaveforms{neuron}))/abs(max(averageWaveforms{neuron}));
    [~, ~, wInv, pInv] = findpeaks(averageWaveforms{neuron}*-1);
    [~, maxIdxInv] = max(pInv);
    halfPeakWidth{neuron} = wInv(maxIdxInv);
    disp(['completed neuron' num2str(neuron)])
catch
end
    end
end


if includeWaveforms
spikeStruct= struct('times', spikeTimeArray, ...
    'region', goodCellRegions(enoughSpikes), ...
    'channel', goodChannels(enoughSpikes), ...
    'label', neuronLabels(enoughSpikes), ...
    'KSLabel', KSLabels(enoughSpikes), ... 
    'cluster', clusterID(enoughSpikes),...
   'fr', fr, ...
    'waveform', averageWaveforms, ...
    'halfValleyWidth', halfValleyWidth, ...
    'halfPeakWidth', halfPeakWidth, ...
    'peak2valley', peak2valley);

else
    spikeStruct= struct('times', spikeTimeArray, ...
    'region', goodCellRegions(enoughSpikes), ...
    'channel', goodChannels(enoughSpikes), ...
    'label', neuronLabels(enoughSpikes), ...
    'KSLabel', KSLabels(enoughSpikes), ... 
    'cluster', clusterID(enoughSpikes),...
   'fr', fr);
   end
    