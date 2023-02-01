function spikeStruct = get_spike_info(sessPath)
    
%Getting spike info from Kilosort3 files
UnsortedSpikeTimes = double(readNPY(strcat(sessPath, '\spike_times.npy')));
UnsortedSpikeClusters = double(readNPY(strcat(sessPath, '\spike_clusters.npy')))+1;
ClusterInfo = tdfread(strcat(sessPath, '\cluster_info.tsv'));

%Combining your manually curated clusters (if any) with those that kilosort
%automatically assigns
for Cluster = 1:length(ClusterInfo.id)
    if isnan(ClusterInfo.group(Cluster,1))
        ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1); 
    elseif regexp('   ', ClusterInfo.group(Cluster,:)) == 1
        ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1);
    elseif regexp('    ', ClusterInfo.group(Cluster,:)) == 1
        ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1);
    elseif regexp('     ', ClusterInfo.group(Cluster,:)) == 1
        ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1);
    end
end

%Pulling out only the clusters labeled 'good' (the ones that start with a 'g')
%and putting them into a matrix called GoodClusters
GoodClusters = ClusterInfo.id(ismember(ClusterInfo.group(:,1),'g') == 1)+1;
ClusterInfo.ch = ClusterInfo.ch + 1; 
GoodChannels = num2cell(ClusterInfo.ch(ismember(ClusterInfo.group(:,1),'g') == 1)); 

SpikeTimeArray = cell(length(GoodClusters), 1);

for Cluster = 1:length(GoodClusters)
    SpikeTimeArray{Cluster} = (UnsortedSpikeTimes(UnsortedSpikeClusters == GoodClusters(Cluster))');
end

spikeStruct= struct('times', SpikeTimeArray, 'regions', [], 'channels', GoodChannels);

