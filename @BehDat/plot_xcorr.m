function plot_xcorr(obj, ref, target, window)

edges = 0:30:obj.info.samples;
refSpikes = histcounts(obj.spikes(ref).times, 'BinEdges', edges);
targetSpikes = histcounts(obj.spikes(target).times, 'BinEdges', edges);
figure
plot(xcorr(refSpikes, targetSpikes, window))
set(gcf, 'Position', get(0, 'Screensize'));