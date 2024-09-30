function isAuto = find_auto(obj)

% Returns an identity matrix equal in size on a side to the number of
% neurons in the session, marking neurons as true if an autocorrelation is
% found between multiple neurons.

spikes = obj.bin_spikes([0 obj.info.samples], 1);
numNeurons = size(spikes, 1);
if numNeurons == 1
    isAuto = false;
    return
end
isAuto = false(numNeurons);
for ref = 1:numNeurons - 1
    refSpikes = spikes(ref, :);
    parfor target = ref + 1:numNeurons
        
        targetSpikes = spikes(target, :);
        baseCorr = xcorr(refSpikes, targetSpikes, 0);
        numRefSpikes = sum(refSpikes);
        numTargetSpikes = sum(targetSpikes);
        if baseCorr > min(numRefSpikes, numTargetSpikes)/2
            figure
            plot(baseCorr)
            title(sprintf("Ref %d, target %d", ref, target))
            isAuto(ref, target) = true;
        end
    end
end

[SameRow, SameColumn] = find(isAuto);
SameNeuronChannels = horzcat(SameRow, SameColumn);
% SameRowCount = SpikeCounts(SameRow);
% SameColumnCount = SpikeCounts(SameColumn);
% SameNeuronSpikeCounts = horzcat(SameRowCount, SameColumnCount);
% Figuring out which neurons are the same as which other neurons, and
% removing all but the highest firing rate duplicates
Groups = graph(SameNeuronChannels(:,1), SameNeuronChannels(:,2));
figure;
plot(Groups)
[~, sessStr] = fileparts(obj.info.path);
title(sessStr)