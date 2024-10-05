function plot_xcorr(obj, ref, target, window)

% Plots the cross correlogram of two neurons in a given window
% INPUT:
%     ref - index of the reference neuron
%     target - index of the target neuron
%     window - number of bins to correlate on either side of the center

edges = 0:30:obj.info.samples;
refSpikes = histcounts(obj.spikes(ref).times, 'BinEdges', edges);
targetSpikes = histcounts(obj.spikes(target).times, 'BinEdges', edges);
figure
plot(xcorr(refSpikes, targetSpikes, window))
