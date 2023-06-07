function E = plot_digraph(obj, trialized, panel)

% This function currently only accepts trialized weights from excitatory
% connections, should be modified to parse name-value pair arguments and
% accept excitatory and inhibitory weights. It plots the network graph of
% the neurons with significant cross correlations and their weights. The 
% size of the nodes is proportional to the number of spikes in the neuron.
% If the argument trialized is given, it should be the output from the
% function trialize_mono_excitatory. This will plot the average weights
% from the trialized data.

if ~exist('trialized', 'var')
    trialized = [];
end

if exist('panel', 'var')
    h = figure('Visible', 'off');
else
    h = figure;
end

numNeurons = numel(obj.spikes);
animalName = obj.info.name;
connGraphEx = {[], []};
connGraphIn = {[], []};
weightsEx = [];
weightsExTrialized = [];
weightsIn = [];
sizes = zeros(1, numNeurons);
labels = cell(1, numNeurons);
for ref = 1:numNeurons
    sizes(ref) = numel(obj.spikes(ref).times)/obj.info.samples;
    label = obj.spikes(ref).region + ", " + string(ref);
    labels{ref} = label{1};
    % Excitatory
    numExcite = numel(obj.spikes(ref).exciteOutput);
    if numExcite
        for t = 1:numExcite
            target = obj.spikes(ref).exciteOutput(t);
            connGraphEx{1}(end+1) = ref;
            connGraphEx{2}(end+1) = target;
            weightsEx(end+1) = obj.spikes(ref).exciteWeight(t);
            try
                weightsExTrialized(end+1) = trialized(ref).weights(t);
            catch
            end
        end
    end

    % Inhibitory
    numInhib = numel(obj.spikes(ref).inhibitOutput);
    if numInhib
        for t = 1:numInhib
            target = obj.spikes(ref).inhibitOutput(t);
            connGraphIn{1}(end+1) = ref;
            connGraphIn{2}(end+1) = target;
            weightsIn(end+1) = obj.spikes(ref).inhibitWeight(t);
        end
    end 
end

if (isempty(connGraphEx{1}))
%     figure
    E = plot(digraph(connGraphEx{1}, connGraphEx{2}));
    return
end
%% Plots

%Excitatory
connGraphEx = digraph(connGraphEx{1}, connGraphEx{2});
% figure
if ~isempty(trialized)
    weightsEx = weightsExTrialized;
    weightsEx(weightsEx < 0) = 0.01;
end
E = plot(connGraphEx, 'LineWidth', weightsEx,...
    'Layout', 'layered', 'MarkerSize', 1, 'ArrowSize', 10);
title(sprintf("Animal %s", animalName))
labels = labels(1:numel(E.XData));
E.NodeLabel = labels;
hold on

% Inhibitory
if ~isempty(weightsIn)
    connGraphIn = digraph(connGraphIn{1}, connGraphIn{2});
    I = plot(connGraphIn, 'LineWidth', 5*weightsIn/max(weightsIn),...
        'Layout', 'layered', 'MarkerSize', 1);
    
    nodeNums = cellfun(@str2num, I.NodeLabel);
    newX = E.XData(nodeNums);
    newY = E.YData(nodeNums);
    I.XData = newX;
    I.YData = newY;
    I.NodeLabel = {};
end

% size data
if ~isempty(trialized)
    fr = extractfield(trialized, 'fr');
%     sizes = cell2mat(fr);
    sizes = fr(1:numel(E.XData));
else
    sizes = sizes(1:numel(E.XData));
end
scatter(E.XData, E.YData, 100*sizes/max(sizes), 'k', 'o', 'filled')

%% Trialized overlay

% if isempty(trialized)
%     return
% end

if exist('panel', 'var')
    copyobj(h.Children, panel)
    close(h)
end