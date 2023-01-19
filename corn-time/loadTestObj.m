spTimes = readNPY('E:\Ephys\Test\spike_times.npy');
spClu = readNPY('E:\Ephys\Test\spike_clusters.npy');
spTimes = double(spTimes);
spClu = double(spClu);
maxClust = max(spClu);
clusts = num2cell(1:maxClust);
times = cell(1, maxClust);
[times{:}] = deal(spTimes);
clustInd = cell(1, maxClust);
[clustInd{:}] = deal(spClu);
spikesByNeur = cellfun(@(x, y, z) x(y == z), times, clustInd, clusts, 'uni', 0);
behObj = NeurDat;
behObj.baud = 30000;
behObj.frames = max(spTimes);
behObj.spikes = spikesByNeur;
behObj.find_mono