function psth(obj, event, edges, neuron, panel, trialTypes)

spikeMat = obj.bin_neuron(event, edges, neuron, 1, trialTypes);
meanSpikes = mean(spikeMat, 1);
smoothSpikes = smoothdata(meanSpikes, 'Gaussian', 50);
if exist('panel', 'var')
    h = figure('Visible', 'off');
    plot(smoothSpikes * 2000)    
    copyobj(h.Children, panel)
    close(h)
    return
end
    
plot(smoothSpikes * 2000)    

% set(gcf, 'Position', get(0, 'Screensize'));