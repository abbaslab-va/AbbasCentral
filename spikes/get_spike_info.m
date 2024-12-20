function spikeStruct = get_spike_info(sessPath, regions, includeMua)
    
% OUTPUT:
%     spikeStruct - a non-scalar structure containing spike info for a BehDat class
% INPUT:
%     sessPath - path to the behavioral session folder
%     regions - regions sourced from ini.regions. See docs for details

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
if isempty(goodClusters)
    spikeStruct=[];
    return 
end
clusterInfo.ch = clusterInfo.ch + 1; 
goodChannels = clusterInfo.ch(ismember(clusterInfo.group(:,1),'g') == 1); 
muaChannels = clusterInfo.ch(ismember(clusterInfo.group(:, 1),'m') == 1);
goodChannels = num2cell(goodChannels);
muaChannels = num2cell(muaChannels);
numGoodCells = length(goodClusters);
numMuaCells = length(muaClusters);
spikeTimeArray = cell(numGoodCells, 1);
muaArray = cell(numMuaCells, 1);

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

% This is a resource-heavy step, try/catch to skip waveforms if memory
% insufficient.
try
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
rawData = NS6.Data;
neuronChannels = rawData([cell2mat(goodChannels), cell2mat(muaChannels)], :);
goodLabels = cell(numGoodCells, 1);
[goodLabels{:}] = deal('good');
if includeMua
    numNeurons = numGoodCells + numMuaCells;
    spikeTimeArray = [spikeTimeArray; muaArray];
    muaLabels = cell(numMuaCells, 1);
    [muaLabels{:}] = deal('mua');
    neuronLabels = [goodLabels; muaLabels];
else
    numNeurons = numGoodCells;
    neuronLabels = goodLabels;
end
numSamples = length(NS6.Data);
averageWaveforms = cell(numNeurons,1);
fr = averageWaveforms;
halfValleyWidth = averageWaveforms;
halfPeakWidth = averageWaveforms;
peak2valley = averageWaveforms;
%%
parfor neuron = 1:numNeurons
    totalSpikes = length(spikeTimeArray{neuron});
    numspikes=1000;
    if totalSpikes < numspikes
        numspikes = length(spikeTimeArray{neuron});
    end
    if ~numspikes
        continue
    end
    chanData = neuronChannels(neuron, :)
    highPassedData = highpass(single(chanData(1:spikeTimeArray{neuron}(numspikes))), 500, 30000);
    averageWaveforms{neuron} = zeros(numspikes,101);
    for spike = 1:numspikes
        try
            averageWaveforms{neuron}(spike,:) = highPassedData(spikeTimeArray{neuron}(spike)-50 : spikeTimeArray{neuron}(spike)+50);
        catch
        end
    end      

    fr{neuron} = totalSpikes/(numSamples/30000);

    % Waveform metrics
    averageWaveforms{neuron} = mean(averageWaveforms{neuron});
    [~, ~, w, p] = findpeaks(averageWaveforms{neuron});
    [~, maxIdx] = max(p);
    halfValleyWidth{neuron} = w(maxIdx);
    peak2valley{neuron} = abs(min(averageWaveforms{neuron}))/abs(max(averageWaveforms{neuron}));

    [~, ~, wInv, pInv] = findpeaks(averageWaveforms{neuron}*-1);
    [~, maxIdxInv] = max(pInv);
    halfPeakWidth{neuron} = wInv(maxIdxInv);
end

spikeStruct= struct('times', spikeTimeArray, 'region', goodCellRegions, 'channel', goodChannels, 'label', neuronLabels, ...
    'fr', fr, 'waveform', averageWaveforms, 'halfValleyWidth',halfValleyWidth,'halfPeakWidth',halfPeakWidth,'peak2valley', peak2valley);
catch
    disp('No waveforms - likely need more RAM - continueing without')
    [~, child] = fileparts(sessPath);

%NS6 = openNSx(fullfile(sessPath,strcat(child,'.ns6')),'noread');
% if NS6 == -1
%     NS6_dir = dir('*.ns6');
%     NS6 = openNSx(fullfile(sessPath,NS6_dir.name),'noread');    
% end
    numSamples = NS6.MetaTags.DataPoints;
parfor neuron = 1:numNeurons
    totalSpikes = length(spikeTimeArray{neuron});
    fr{neuron} = totalSpikes/(numSamples/30000);
end
    spikeStruct= struct('times', spikeTimeArray, 'region', goodCellRegions, 'channel', goodChannels, ...
    'fr', fr);
end


