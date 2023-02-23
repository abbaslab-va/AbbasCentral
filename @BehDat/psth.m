function psth(obj, event, edges, neuron, ax)

spikeMat = obj.bin_neuron(event, edges, neuron, 1);
meanSpikes = mean(spikeMat, 1);
smoothSpikes = smoothdata(meanSpikes, 'Gaussian', 50);
if exist('ax', 'var')
    h = figure('Visible', 'off');
    plot(smoothSpikes * 2000)    
    copyobj(h.Children, ax)
    close(h)
    return
end
    
plot(smoothSpikes * 2000)    

% set(gcf, 'Position', get(0, 'Screensize'));