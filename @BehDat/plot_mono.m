function plot_mono(obj)

numNeurons = numel(obj.spikes);
numFrames = obj.info.samples;
for ref = 1:numNeurons
    for target = 1:numNeurons
        if obj.
            targetNeuron = obj.spikes(n).outputExcite;
            leadingRegion = obj.spikes(n).regions;
            targetRegion = obj.spikes(targetNeuron).regions;
            allSpikes = obj.bin_spikes([0 numFrames], 1);
            refSpikes = allSpikes(n, :);
            targetSpikes = allSpikes(targetNeuron, :);
            figure
            plot(xcorr(refSpikes, targetSpikes, 50))
            title(sprintf("Ref region: %s  Target region: %s", leadingRegion, targetRegion))
        end
    end
end