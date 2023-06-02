function spikeStruct = get_spike_info(sessPath, regions)
    
% OUTPUT:
%     spikeStruct - a non-scalar structure containing spike info for a BehDat class
% INPUT:
%     sessPath - path to the behavioral session folder
%     regions - regions sourced from ini.regions. See docs for details

%Getting spike info from Kilosort3 files
unsortedSpikeTimes = double(readNPY(strcat(sessPath, '\spike_times.npy')));
unsortedSpikeClusters = double(readNPY(strcat(sessPath, '\spike_clusters.npy')))+1;
clusterInfo = tdfread(strcat(sessPath, '\cluster_info.tsv'));

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
if isempty(goodClusters)
    spikeStruct=[];
    return 
end
clusterInfo.ch = clusterInfo.ch + 1; 
goodChannels = clusterInfo.ch(ismember(clusterInfo.group(:,1),'g') == 1); 

goodChannels=num2cell(goodChannels);
numCells = length(goodClusters);
spikeTimeArray = cell(numCells, 1);

cellRegions = cell(numCells, 1);
allRegions = fields(regions);
for cluster = 1:numCells
    spikeTimeArray{cluster} = (unsortedSpikeTimes(unsortedSpikeClusters == goodClusters(cluster))');
    for r = 1:numel(allRegions)
        regionField = allRegions{r};
        if ismember(goodChannels{cluster}, regions.(regionField))
            cellRegions{cluster} = regionField;
            break
        end
    end
end
% Get Waveforms and Waveform metrics

[parent, child]=fileparts(sessPath);
NS6=openNSx(fullfile(sessPath,strcat(child,'.ns6')));


averageWaveforms = cell(length(goodClusters),1);
%%
for neuron = 1:length(goodClusters)
    numspikes=1000;
    if length(spikeTimeArray{neuron})<numspikes
        numspikes=length(spikeTimeArray{neuron});
    end
    channel=goodChannels{neuron};
    highPassedData = highpass(single(NS6.Data(channel, 1:spikeTimeArray{neuron}(numspikes))), 500, 30000);
    averageWaveforms{neuron} = zeros(numspikes,101);
    for spike = 1:numspikes
        try
            averageWaveforms{neuron}(spike,:) = highPassedData(spikeTimeArray{neuron}(spike)-50 : spikeTimeArray{neuron}(spike)+50);
        catch
        end
    end      
    averageWaveforms{neuron} = mean(averageWaveforms{neuron});
end
%%
% Waveform metrics 

for n=1:length(averageWaveforms)
    [pks,locs,w,p]=findpeaks(averageWaveforms{n});
    [max_val,max_idx]=max(p);
    halfValleyWidth(n,1)=w(max_idx);
    peak2valley(n,1)=abs(min(averageWaveforms{n}))/abs(max(averageWaveforms{n}));
end

for n=1:length(averageWaveforms)
    [pks,locs,w,p]=findpeaks(averageWaveforms{n}*-1);
    [max_val,max_idx]=max(p);
    halfPeakWidth(n,1)=w(max_idx);
end

% firing rate 
for n=1:size(spikeTimeArray,1)
    fr(n,1)=length(spikeTimeArray{n})/(length(NS6.Data)/30000);
end 

fr=num2cell(fr);
halfValleyWidth=num2cell(halfValleyWidth);
halfPeakWidth=num2cell(halfPeakWidth);
peak2valley=num2cell(peak2valley);
%% Create structure 

spikeStruct= struct('times', spikeTimeArray, 'region', cellRegions, 'channel', goodChannels, ...
    'fr', fr, 'waveform', averageWaveforms, 'halfValleyWidth',halfValleyWidth,'halfPeakWidth',halfPeakWidth,'peak2valley', peak2valley);

