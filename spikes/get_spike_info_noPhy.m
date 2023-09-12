function spikeStruct = get_spike_info_noPhy(sessPath)

% Get all SUA only clusters from kilosort (phy  not required)
%Getting spike info from Kilosort3 files
UnsortedSpikeTimes = double(readNPY([sessPath, '\spike_times.npy']));
UnsortedSpikeClusters = double(readNPY([sessPath  '\spike_clusters.npy']))+1;
ClusterKSLabel = tdfread([sessPath, '\cluster_KSLabel.tsv']);

GoodClusters = ClusterKSLabel.cluster_id(ismember(ClusterKSLabel.KSLabel(:,1),'g'))+1;

%Creates a cell array with each 'good' cluster on a separate row, matches 
%spike times for each cluster, and gets bursting and average waveform for each cluster
SpikeTimeArray = cell(length(GoodClusters), 1);
nevDir = dir(fullfile(sessPath, '*.nev'));
nevFile = fullfile(sessPath, nevDir.name);
NEV = openNEV(nevFile);
numSamples = double(NEV.MetaTags.DataDuration);

for Neuron = 1:length(GoodClusters)
    
    SpikeTimeArray{Neuron} = (UnsortedSpikeTimes(UnsortedSpikeClusters == GoodClusters(Neuron))');
 
    fr{Neuron, 1} = numel(SpikeTimeArray{Neuron})/(numSamples/NEV.MetaTags.SampleRes);
end




%Converting into a more organized structure
if ~isempty(SpikeTimeArray)
    spikeStruct= struct('times', SpikeTimeArray, 'fr', fr);
else
    spikeStruct = []; % if recording doesn't have clusters
end