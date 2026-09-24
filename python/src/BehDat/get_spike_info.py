from brpylib import NevFile
import numpy as np
import pandas as pd

nevDir =  'E:\\Ephys\\MD_19_4Hz_20Hz_sesh_2\\MD_19_4Hz_20Hz_sesh_2.nev'
spikeDir = 'E:\\Ephys\\MD_19_4Hz_20Hz_sesh_2\\spike_times.npy'
clusterDir = 'E:\\Ephys\\MD_19_4Hz_20Hz_sesh_2\\spike_clusters.npy'
clusterInfoDir = 'E:\\Ephys\\MD_19_4Hz_20Hz_sesh_2\\cluster_info.tsv'

NEV = NevFile(nevDir)
unsortedSpikeTimes = np.load(spikeDir)
unsortedSpikeClusters = np.load(clusterDir)
clusterInfo = pd.read_csv(clusterInfoDir)
ksGoodFragment = 'good\\t\\'
ksMuaFragment = 'mua\\t\\'
goodLabel = 'good\\t'
# assign cluster identity based on cluster_info.tsv 
goodClusters = clusterInfo.apply(lambda row: goodFragment in row.to_string(), axis=1)
muaClusters = clusterInfo.apply(lambda row: muaFragment in row.to_string(), axis=1)
