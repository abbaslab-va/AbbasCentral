function psth(obj, event, edges, neuron)

spikeMat = obj.bin_neuron(event, edges, neuron, 1);
meanSpikes = mean(spikeMat, 1);
smoothSpikes = smoothdata(meanSpikes, 'Gaussian', 50);
figure
plot(smoothSpikes * 2000)
% set(gcf, 'Position', get(0, 'Screensize'));