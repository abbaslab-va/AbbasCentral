function plot_digraph(obj)

numNeurons = numel(obj.spikes);
animalName = obj.info.name;
connGraph = {[], []};
for ref = 1:numNeurons
    if isempty(obj.spikes(ref).exciteOutput)
        continue
    end
    for t = 1:numel(obj.spikes(ref).exciteOutput)
        target = obj.spikes(ref).exciteOutput(t);
%         leadingRegion = obj.spikes(ref).region;
%         targetRegion = obj.spikes(t).region;
        sessCorr = obj.spikes(ref).exciteXcorr(t, :); 
        peakVal = find(sessCorr == max(sessCorr));
        if peakVal < 51
            connGraph{1}(end+1) = ref;
            connGraph{2}(end+1) = target;
        else
            connGraph{1}(end+1) = target;
            connGraph{2}(end+1) = ref;
        end
    end
end
connGraph = digraph(connGraph{1}, connGraph{2});
figure
plot(connGraph)
title(sprintf("Animal %s", animalName))