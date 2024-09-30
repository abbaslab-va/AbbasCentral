function remove_duplicate_neurons(obj)
% This method modifies the spike field of the object and removes neurons
% who are strongly autocorrelated with other neurons in the sessions,
% keeping only the neuron who's firing rate is the highest in the cluster.
% WARNING: WILL PERMANENTLY MODIFY YOUR OBJECT. ONLY RUN IF YOU HAVE A
% SAVED COPY OF THE ORIGINAL OBJECT.

autoIdx = obj.find_auto;
if ~autoIdx
    return
end
SpikeCounts = arrayfun(@(x) numel(x.times), obj.spikes);
[SameRow, SameColumn] = find(autoIdx);
SameNeuronChannels = horzcat(SameRow, SameColumn);
SameRowCount = SpikeCounts(SameRow);
SameColumnCount = SpikeCounts(SameColumn);
SameNeuronSpikeCounts = horzcat(SameRowCount, SameColumnCount);
% Figuring out which neurons are the same as which other neurons, and
% removing all but the highest firing rate duplicates
Groups = graph(SameNeuronChannels(:,1), SameNeuronChannels(:,2));
Clusters = conncomp(Groups);
deleteNeurons = [];
for shuffle = 1:max(Clusters)
    nIndices = find(Clusters == shuffle);
    if numel(nIndices) > 1
        groupFR = SpikeCounts(nIndices);
        deleteIndices = groupFR ~= max(groupFR);
        deleteNeurons(end+1:end+numel(find(deleteIndices))) = nIndices(deleteIndices);
    end
end

obj.spikes(deleteNeurons) = [];
