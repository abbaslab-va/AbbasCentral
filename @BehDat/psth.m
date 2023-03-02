function psth(obj, event, edges, neuron, panel, trialTypes)

% INPUT:
%     event - a string of a state named in the config file
%     edges - 1x2 vector distance from event on either side in seconds
%     neuron - index of neuron from spike field of object
%     panel - an optional handle to a panel (in the AbbasCentral app)
%     trialTypes - an optional argument specifying the trial type to bin

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